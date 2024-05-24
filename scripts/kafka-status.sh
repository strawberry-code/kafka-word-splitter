#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kafka Word Splitter - Infrastructure Status${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Detect container runtime
detect_runtime() {
    if command -v podman &> /dev/null; then
        echo "podman"
        return 0
    fi

    if command -v docker &> /dev/null; then
        echo "docker"
        return 0
    fi

    echo ""
    return 1
}

RUNTIME=$(detect_runtime)

if [ -z "$RUNTIME" ]; then
    echo -e "${RED}ERROR: No container runtime found!${NC}"
    exit 1
fi

echo -e "${BLUE}Container Runtime Status:${NC}"
echo -e "  Runtime: ${GREEN}${RUNTIME}${NC}"
echo ""

# Check container status
echo -e "${BLUE}Container Status:${NC}"

ZOOKEEPER_STATUS="STOPPED"
KAFKA_STATUS="STOPPED"

case "$RUNTIME" in
    "podman")
        if podman ps --filter "name=kafka-word-splitter-zookeeper" --format "{{.Names}}\t{{.Status}}" | grep -q "zookeeper"; then
            ZOOKEEPER_STATUS=$(podman ps --filter "name=kafka-word-splitter-zookeeper" --format "{{.Status}}")
            echo -e "  ${GREEN}✓${NC} Zookeeper: ${GREEN}RUNNING${NC} (${ZOOKEEPER_STATUS})"
        else
            echo -e "  ${RED}✗${NC} Zookeeper: ${RED}STOPPED${NC}"
        fi

        if podman ps --filter "name=kafka-word-splitter-kafka" --format "{{.Names}}\t{{.Status}}" | grep -q "kafka"; then
            KAFKA_STATUS=$(podman ps --filter "name=kafka-word-splitter-kafka" --format "{{.Status}}")
            echo -e "  ${GREEN}✓${NC} Kafka: ${GREEN}RUNNING${NC} (${KAFKA_STATUS})"
        else
            echo -e "  ${RED}✗${NC} Kafka: ${RED}STOPPED${NC}"
        fi
        ;;
    "docker")
        if docker ps --filter "name=kafka-word-splitter-zookeeper" --format "{{.Names}}\t{{.Status}}" | grep -q "zookeeper"; then
            ZOOKEEPER_STATUS=$(docker ps --filter "name=kafka-word-splitter-zookeeper" --format "{{.Status}}")
            echo -e "  ${GREEN}✓${NC} Zookeeper: ${GREEN}RUNNING${NC} (${ZOOKEEPER_STATUS})"
        else
            echo -e "  ${RED}✗${NC} Zookeeper: ${RED}STOPPED${NC}"
        fi

        if docker ps --filter "name=kafka-word-splitter-kafka" --format "{{.Names}}\t{{.Status}}" | grep -q "kafka"; then
            KAFKA_STATUS=$(docker ps --filter "name=kafka-word-splitter-kafka" --format "{{.Status}}")
            echo -e "  ${GREEN}✓${NC} Kafka: ${GREEN}RUNNING${NC} (${KAFKA_STATUS})"
        else
            echo -e "  ${RED}✗${NC} Kafka: ${RED}STOPPED${NC}"
        fi
        ;;
esac

echo ""

# Check connectivity
echo -e "${BLUE}Connectivity Status:${NC}"

# Check Zookeeper connectivity (port 2181)
if timeout 2 bash -c "echo > /dev/tcp/localhost/2181" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Zookeeper (localhost:2181): ${GREEN}REACHABLE${NC}"
else
    echo -e "  ${RED}✗${NC} Zookeeper (localhost:2181): ${RED}UNREACHABLE${NC}"
fi

# Check Kafka connectivity (port 9092)
if timeout 2 bash -c "echo > /dev/tcp/localhost/9092" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Kafka (localhost:9092): ${GREEN}REACHABLE${NC}"
else
    echo -e "  ${RED}✗${NC} Kafka (localhost:9092): ${RED}UNREACHABLE${NC}"
fi

echo ""

# List topics if Kafka is running
if [ "$KAFKA_STATUS" != "STOPPED" ]; then
    echo -e "${BLUE}Kafka Topics:${NC}"

    TOPICS=""
    case "$RUNTIME" in
        "podman")
            TOPICS=$(podman exec kafka-word-splitter-kafka kafka-topics.sh --list --bootstrap-server localhost:9092 2>/dev/null || echo "")
            ;;
        "docker")
            TOPICS=$(docker exec kafka-word-splitter-kafka kafka-topics.sh --list --bootstrap-server localhost:9092 2>/dev/null || echo "")
            ;;
    esac

    if [ -n "$TOPICS" ]; then
        echo "$TOPICS" | while read -r topic; do
            if [ -n "$topic" ]; then
                echo -e "  - ${GREEN}${topic}${NC}"
            fi
        done

        TOPIC_COUNT=$(echo "$TOPICS" | grep -v "^$" | wc -l | tr -d ' ')
        echo ""
        echo -e "  Total topics: ${GREEN}${TOPIC_COUNT}${NC}"
    else
        echo -e "  ${YELLOW}No topics found or unable to list topics${NC}"
        echo -e "  ${YELLOW}You may need to create topics first: ./scripts/create-topics.sh${NC}"
    fi
else
    echo -e "${YELLOW}Kafka is not running. Start with: ./start-kafka.sh${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"

# Overall status summary
if [ "$ZOOKEEPER_STATUS" != "STOPPED" ] && [ "$KAFKA_STATUS" != "STOPPED" ]; then
    echo -e "${GREEN}Overall Status: ALL SYSTEMS OPERATIONAL${NC}"
else
    echo -e "${YELLOW}Overall Status: SERVICES NOT RUNNING${NC}"
    echo -e "Start services with: ${BLUE}./start-kafka.sh${NC}"
fi

echo -e "${BLUE}========================================${NC}"
echo ""
