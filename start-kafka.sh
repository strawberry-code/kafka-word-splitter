#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kafka Word Splitter - Starting Kafka Infrastructure${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Detect container runtime and compose tool
detect_runtime() {
    if command -v podman &> /dev/null; then
        if podman compose version &> /dev/null; then
            echo "podman compose"
            return 0
        elif command -v podman-compose &> /dev/null; then
            echo "podman-compose"
            return 0
        fi
    fi

    if command -v docker &> /dev/null; then
        if docker compose version &> /dev/null; then
            echo "docker compose"
            return 0
        elif command -v docker-compose &> /dev/null; then
            echo "docker-compose"
            return 0
        fi
    fi

    echo ""
    return 1
}

RUNTIME=$(detect_runtime)

if [ -z "$RUNTIME" ]; then
    echo -e "${RED}ERROR: No container runtime found!${NC}"
    echo ""
    echo "Please install one of the following:"
    echo "  - Podman with podman-compose (recommended)"
    echo "  - Docker with docker compose"
    echo ""
    echo "Installation instructions:"
    echo "  Podman: https://podman.io/getting-started/installation"
    echo "  Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}Detected runtime: ${RUNTIME}${NC}"
echo ""

# Check for compose file
COMPOSE_FILE="compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    # Fallback to docker-compose.yml for backward compatibility
    COMPOSE_FILE="docker-compose.yml"
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo -e "${RED}ERROR: No compose file found (compose.yml or docker-compose.yml)${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Using legacy docker-compose.yml (consider migrating to compose.yml)${NC}"
fi

echo -e "${BLUE}Starting Kafka infrastructure...${NC}"

# Start services
case "$RUNTIME" in
    "podman compose")
        podman compose -f "$COMPOSE_FILE" up -d
        ;;
    "podman-compose")
        podman-compose -f "$COMPOSE_FILE" up -d
        ;;
    "docker compose")
        docker compose -f "$COMPOSE_FILE" up -d
        ;;
    "docker-compose")
        docker-compose -f "$COMPOSE_FILE" up -d
        ;;
esac

echo ""
echo -e "${BLUE}Waiting for services to be ready...${NC}"
sleep 5

# Validate services are running
echo ""
echo -e "${BLUE}Checking service status...${NC}"

ZOOKEEPER_RUNNING=false
KAFKA_RUNNING=false

case "$RUNTIME" in
    "podman compose"|"podman-compose")
        if podman ps --filter "name=kafka-word-splitter-zookeeper" --format "{{.Names}}" | grep -q "zookeeper"; then
            ZOOKEEPER_RUNNING=true
        fi
        if podman ps --filter "name=kafka-word-splitter-kafka" --format "{{.Names}}" | grep -q "kafka"; then
            KAFKA_RUNNING=true
        fi
        ;;
    "docker compose"|"docker-compose")
        if docker ps --filter "name=kafka-word-splitter-zookeeper" --format "{{.Names}}" | grep -q "zookeeper"; then
            ZOOKEEPER_RUNNING=true
        fi
        if docker ps --filter "name=kafka-word-splitter-kafka" --format "{{.Names}}" | grep -q "kafka"; then
            KAFKA_RUNNING=true
        fi
        ;;
esac

if [ "$ZOOKEEPER_RUNNING" = true ]; then
    echo -e "  ${GREEN}✓${NC} Zookeeper is running"
else
    echo -e "  ${RED}✗${NC} Zookeeper is NOT running"
fi

if [ "$KAFKA_RUNNING" = true ]; then
    echo -e "  ${GREEN}✓${NC} Kafka is running"
else
    echo -e "  ${RED}✗${NC} Kafka is NOT running"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Kafka Infrastructure Started Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Connection Information:"
echo "  Kafka Broker:  localhost:9092"
echo "  Zookeeper:     localhost:2181"
echo ""
echo "Next Steps:"
echo "  1. Create topics: ./scripts/create-topics.sh"
echo "  2. Check status: ./scripts/kafka-status.sh"
echo "  3. Stop services: ./scripts/stop-kafka.sh"
echo ""
