#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}Kafka Word Splitter - Podman Migration Validation${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""

VALIDATION_PASSED=0
VALIDATION_FAILED=0
VALIDATION_WARNINGS=0

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((VALIDATION_PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((VALIDATION_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠ WARN:${NC} $1"
    ((VALIDATION_WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ INFO:${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
}

# 1. Check Runtime Installation
section "Runtime Installation"

if command -v podman &> /dev/null; then
    PODMAN_VERSION=$(podman --version)
    pass "Podman is installed: $PODMAN_VERSION"
else
    fail "Podman is not installed"
fi

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    warn "Docker is also installed: $DOCKER_VERSION (not required but supported)"
fi

# 2. Check Compose Tool Availability
section "Compose Tool Availability"

COMPOSE_AVAILABLE=false

if command -v podman &> /dev/null; then
    if podman compose version &> /dev/null; then
        COMPOSE_VERSION=$(podman compose version)
        pass "podman compose is available: $COMPOSE_VERSION"
        COMPOSE_AVAILABLE=true
    else
        fail "podman compose is not available"
    fi

    if command -v podman-compose &> /dev/null; then
        PODMAN_COMPOSE_VERSION=$(podman-compose --version)
        info "podman-compose is also available: $PODMAN_COMPOSE_VERSION"
    fi
fi

if [ "$COMPOSE_AVAILABLE" = false ]; then
    fail "No compose tool available for Podman"
fi

# 3. Verify Compose File
section "Compose File Validation"

if [ -f "compose.yml" ]; then
    pass "compose.yml exists"

    # Check version
    if grep -q "^version: '3.8'" compose.yml; then
        pass "compose.yml uses version 3.8"
    else
        fail "compose.yml does not use version 3.8"
    fi

    # Check for Docker socket mount (should NOT exist)
    if grep -q "/var/run/docker.sock" compose.yml; then
        fail "compose.yml contains Docker socket mount (Podman incompatible)"
    else
        pass "compose.yml does not contain Docker socket mount"
    fi

    # Check for container names
    if grep -q "container_name: kafka-word-splitter-zookeeper" compose.yml; then
        pass "compose.yml defines Zookeeper container name"
    else
        fail "compose.yml missing Zookeeper container name"
    fi

    if grep -q "container_name: kafka-word-splitter-kafka" compose.yml; then
        pass "compose.yml defines Kafka container name"
    else
        fail "compose.yml missing Kafka container name"
    fi

    # Check for network configuration
    if grep -q "networks:" compose.yml; then
        pass "compose.yml defines network configuration"
    else
        fail "compose.yml missing network configuration"
    fi

    # Check for depends_on
    if grep -q "depends_on:" compose.yml; then
        pass "compose.yml includes depends_on for startup order"
    else
        warn "compose.yml missing depends_on (recommended for startup order)"
    fi
else
    fail "compose.yml not found"

    # Check for old docker-compose.yml
    if [ -f "docker-compose.yml" ]; then
        warn "docker-compose.yml still exists (should be migrated to compose.yml)"
    fi
fi

# 4. Verify Scripts Exist and Are Executable
section "Script Validation"

SCRIPTS=(
    "start-kafka.sh"
    "scripts/stop-kafka.sh"
    "scripts/kafka-status.sh"
    "scripts/create-topics.sh"
    "scripts/validate-podman.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            pass "$(basename $script) exists and is executable"
        else
            fail "$(basename $script) exists but is NOT executable"
        fi

        # Check for runtime detection in scripts
        if grep -q "detect_runtime" "$script" 2>/dev/null; then
            pass "$(basename $script) includes runtime detection"
        else
            if [ "$(basename $script)" != "validate-podman.sh" ]; then
                warn "$(basename $script) may not include runtime detection"
            fi
        fi
    else
        fail "$(basename $script) not found"
    fi
done

# 5. Test Service Startup (if not already running)
section "Service Startup Test"

# Detect runtime
RUNTIME=""
if command -v podman &> /dev/null && podman compose version &> /dev/null; then
    RUNTIME="podman"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    RUNTIME="docker"
fi

if [ -n "$RUNTIME" ]; then
    # Check if services are already running
    SERVICES_RUNNING=false

    case "$RUNTIME" in
        "podman")
            if podman ps --filter "name=kafka-word-splitter" --format "{{.Names}}" | grep -q "kafka-word-splitter"; then
                SERVICES_RUNNING=true
            fi
            ;;
        "docker")
            if docker ps --filter "name=kafka-word-splitter" --format "{{.Names}}" | grep -q "kafka-word-splitter"; then
                SERVICES_RUNNING=true
            fi
            ;;
    esac

    if [ "$SERVICES_RUNNING" = true ]; then
        info "Services already running, skipping startup test"
        pass "Kafka services are running"
    else
        info "Attempting to start services for validation..."

        if [ -x "start-kafka.sh" ]; then
            if ./start-kafka.sh &> /tmp/kafka-start-test.log; then
                pass "Services started successfully"
                CLEANUP_NEEDED=true
            else
                fail "Failed to start services (see /tmp/kafka-start-test.log)"
                cat /tmp/kafka-start-test.log
            fi
        else
            warn "Cannot test service startup (start-kafka.sh not executable)"
        fi
    fi
else
    warn "No runtime available for service startup test"
fi

# 6. Test Connectivity
section "Connectivity Test"

sleep 2  # Give services a moment to be ready

# Test Zookeeper
if timeout 3 bash -c "echo > /dev/tcp/localhost/2181" 2>/dev/null; then
    pass "Zookeeper is reachable on localhost:2181"
else
    fail "Zookeeper is NOT reachable on localhost:2181"
fi

# Test Kafka
if timeout 3 bash -c "echo > /dev/tcp/localhost/9092" 2>/dev/null; then
    pass "Kafka is reachable on localhost:9092"
else
    fail "Kafka is NOT reachable on localhost:9092"
fi

# 7. Test Topic Creation
section "Topic Creation Test"

if [ -n "$RUNTIME" ]; then
    KAFKA_RUNNING=false

    case "$RUNTIME" in
        "podman")
            if podman ps --filter "name=kafka-word-splitter-kafka" --format "{{.Names}}" | grep -q "kafka"; then
                KAFKA_RUNNING=true
            fi
            ;;
        "docker")
            if docker ps --filter "name=kafka-word-splitter-kafka" --format "{{.Names}}" | grep -q "kafka"; then
                KAFKA_RUNNING=true
            fi
            ;;
    esac

    if [ "$KAFKA_RUNNING" = true ]; then
        # Try to create a test topic
        TEST_TOPIC="validation-test-topic"

        case "$RUNTIME" in
            "podman")
                if podman exec kafka-word-splitter-kafka kafka-topics.sh \
                    --create \
                    --topic "$TEST_TOPIC" \
                    --partitions 1 \
                    --replication-factor 1 \
                    --if-not-exists \
                    --bootstrap-server localhost:9092 &> /dev/null; then
                    pass "Test topic created successfully"

                    # Clean up test topic
                    podman exec kafka-word-splitter-kafka kafka-topics.sh \
                        --delete \
                        --topic "$TEST_TOPIC" \
                        --bootstrap-server localhost:9092 &> /dev/null
                else
                    fail "Failed to create test topic"
                fi
                ;;
            "docker")
                if docker exec kafka-word-splitter-kafka kafka-topics.sh \
                    --create \
                    --topic "$TEST_TOPIC" \
                    --partitions 1 \
                    --replication-factor 1 \
                    --if-not-exists \
                    --bootstrap-server localhost:9092 &> /dev/null; then
                    pass "Test topic created successfully"

                    # Clean up test topic
                    docker exec kafka-word-splitter-kafka kafka-topics.sh \
                        --delete \
                        --topic "$TEST_TOPIC" \
                        --bootstrap-server localhost:9092 &> /dev/null
                else
                    fail "Failed to create test topic"
                fi
                ;;
        esac
    else
        warn "Kafka not running, skipping topic creation test"
    fi
fi

# 8. Documentation Check
section "Documentation Validation"

if [ -f "MIGRATION-NOTES.md" ]; then
    pass "MIGRATION-NOTES.md exists"
else
    fail "MIGRATION-NOTES.md not found"
fi

if [ -f ".podman-migration-checklist.md" ]; then
    pass ".podman-migration-checklist.md exists"
else
    fail ".podman-migration-checklist.md not found"
fi

# Clean up if we started services for testing
if [ "${CLEANUP_NEEDED:-false}" = true ]; then
    section "Cleanup"
    info "Stopping test services..."

    if [ -x "scripts/stop-kafka.sh" ]; then
        ./scripts/stop-kafka.sh &> /dev/null
        info "Test services stopped"
    fi
fi

# Final Report
echo ""
echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""
echo -e "  ${GREEN}Passed:   ${VALIDATION_PASSED}${NC}"
echo -e "  ${RED}Failed:   ${VALIDATION_FAILED}${NC}"
echo -e "  ${YELLOW}Warnings: ${VALIDATION_WARNINGS}${NC}"
echo ""

if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ ALL VALIDATIONS PASSED${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${GREEN}The Podman migration is complete and validated!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ VALIDATION FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${RED}Please fix the failed validations before proceeding.${NC}"
    echo ""
    exit 1
fi
