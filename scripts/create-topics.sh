#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kafka Word Splitter - Creating Topics${NC}"
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

echo -e "${GREEN}Detected runtime: ${RUNTIME}${NC}"
echo ""

# Check if Kafka container is running
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

if [ "$KAFKA_RUNNING" = false ]; then
    echo -e "${RED}ERROR: Kafka container is not running!${NC}"
    echo ""
    echo "Please start Kafka first:"
    echo "  ./start-kafka.sh"
    echo ""
    exit 1
fi

echo -e "${BLUE}Creating Kafka topics (topic-3 through topic-10)...${NC}"
echo ""

# Topics to create (as required by the application)
TOPICS=(3 4 5 6 7 8 9 10)
PARTITIONS=1
REPLICATION_FACTOR=1

# Create each topic
for TOPIC_NUM in "${TOPICS[@]}"; do
    TOPIC_NAME="topic-${TOPIC_NUM}"

    echo -n "Creating ${TOPIC_NAME}... "

    case "$RUNTIME" in
        "podman")
            if podman exec kafka-word-splitter-kafka kafka-topics.sh \
                --create \
                --topic "$TOPIC_NAME" \
                --partitions $PARTITIONS \
                --replication-factor $REPLICATION_FACTOR \
                --if-not-exists \
                --bootstrap-server localhost:9092 &> /dev/null; then
                echo -e "${GREEN}✓ Created${NC}"
            else
                # Check if topic already exists
                if podman exec kafka-word-splitter-kafka kafka-topics.sh \
                    --list \
                    --bootstrap-server localhost:9092 2>/dev/null | grep -q "^${TOPIC_NAME}$"; then
                    echo -e "${YELLOW}Already exists${NC}"
                else
                    echo -e "${RED}✗ Failed${NC}"
                fi
            fi
            ;;
        "docker")
            if docker exec kafka-word-splitter-kafka kafka-topics.sh \
                --create \
                --topic "$TOPIC_NAME" \
                --partitions $PARTITIONS \
                --replication-factor $REPLICATION_FACTOR \
                --if-not-exists \
                --bootstrap-server localhost:9092 &> /dev/null; then
                echo -e "${GREEN}✓ Created${NC}"
            else
                # Check if topic already exists
                if docker exec kafka-word-splitter-kafka kafka-topics.sh \
                    --list \
                    --bootstrap-server localhost:9092 2>/dev/null | grep -q "^${TOPIC_NAME}$"; then
                    echo -e "${YELLOW}Already exists${NC}"
                else
                    echo -e "${RED}✗ Failed${NC}"
                fi
            fi
            ;;
    esac
done

echo ""
echo -e "${BLUE}Verifying created topics...${NC}"
echo ""

# List all topics
echo -e "${GREEN}Available topics:${NC}"

case "$RUNTIME" in
    "podman")
        podman exec kafka-word-splitter-kafka kafka-topics.sh \
            --list \
            --bootstrap-server localhost:9092 2>/dev/null | while read -r topic; do
            if [ -n "$topic" ]; then
                echo -e "  - ${GREEN}${topic}${NC}"
            fi
        done
        ;;
    "docker")
        docker exec kafka-word-splitter-kafka kafka-topics.sh \
            --list \
            --bootstrap-server localhost:9092 2>/dev/null | while read -r topic; do
            if [ -n "$topic" ]; then
                echo -e "  - ${GREEN}${topic}${NC}"
            fi
        done
        ;;
esac

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Topic Creation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Next Steps:"
echo "  1. Check topic details: ${RUNTIME} exec kafka-word-splitter-kafka kafka-topics.sh --describe --bootstrap-server localhost:9092"
echo "  2. Start the application to begin processing"
echo ""
