#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kafka Word Splitter - Stopping Kafka Infrastructure${NC}"
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
        echo -e "${RED}ERROR: No compose file found${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}Stopping Kafka infrastructure...${NC}"

# Stop services
case "$RUNTIME" in
    "podman compose")
        podman compose -f "$COMPOSE_FILE" down
        ;;
    "podman-compose")
        podman-compose -f "$COMPOSE_FILE" down
        ;;
    "docker compose")
        docker compose -f "$COMPOSE_FILE" down
        ;;
    "docker-compose")
        docker-compose -f "$COMPOSE_FILE" down
        ;;
esac

echo ""

# Verify services are stopped
SERVICES_RUNNING=false

case "$RUNTIME" in
    "podman compose"|"podman-compose")
        if podman ps --filter "name=kafka-word-splitter" --format "{{.Names}}" | grep -q "kafka-word-splitter"; then
            SERVICES_RUNNING=true
        fi
        ;;
    "docker compose"|"docker-compose")
        if docker ps --filter "name=kafka-word-splitter" --format "{{.Names}}" | grep -q "kafka-word-splitter"; then
            SERVICES_RUNNING=true
        fi
        ;;
esac

if [ "$SERVICES_RUNNING" = false ]; then
    echo -e "${GREEN}✓ All Kafka services stopped successfully${NC}"
else
    echo -e "${YELLOW}⚠ Some services may still be running${NC}"
    echo "Run './scripts/kafka-status.sh' to check service status"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Kafka Infrastructure Stopped${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
