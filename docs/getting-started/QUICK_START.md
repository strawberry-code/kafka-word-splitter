# Quick Start Guide

Get Kafka Word Splitter running in 5 minutes! This guide will walk you through the fastest path from zero to running application.

## Prerequisites Check

Before starting, verify you have the required software:

```bash
# Check Java version (need 17+)
java -version
# Should show: openjdk version "17.x.x" or higher

# Check Podman (recommended)
podman --version
podman compose version
# Should show: podman version 4.x.x or higher

# OR Check Docker (alternative)
docker --version
docker compose version
# Should show: Docker version 20.x.x or higher
```

If any are missing:

**Java 17:**
- Download from [Adoptium](https://adoptium.net/)

**Podman (Recommended):**
- macOS: `brew install podman` then `podman machine init && podman machine start`
- Linux (Ubuntu/Debian): `sudo apt-get install podman`
- Download: [Podman Installation Guide](https://podman.io/getting-started/installation)

**Docker (Alternative):**
- Download from [Docker Desktop](https://www.docker.com/products/docker-desktop/)

## Step 1: Get the Code (30 seconds)

```bash
# Clone the repository
git clone https://github.com/strawberry-code/kafka-word-splitter.git

# Navigate to the project directory
cd kafka-word-splitter
```

## Step 2: Start Kafka Infrastructure (1 minute)

```bash
# Start Kafka and Zookeeper (auto-detects Podman or Docker)
./start-kafka.sh

# The script will:
# - Detect available container runtime (Podman or Docker)
# - Start Zookeeper and Kafka containers
# - Wait for services to be ready
# - Display connection information
```

You should see output like:
```
========================================
Kafka Word Splitter - Starting Kafka Infrastructure
========================================

Detected runtime: podman compose

Starting Kafka infrastructure...
[+] Running 3/3
 ✔ Network kafka-network    Created
 ✔ Container kafka-word-splitter-zookeeper  Started
 ✔ Container kafka-word-splitter-kafka      Started

Kafka Infrastructure Started Successfully!

Connection Information:
  Kafka Broker:  localhost:9092
  Zookeeper:     localhost:2181

Next Steps:
  1. Create topics: ./scripts/create-topics.sh
  2. Check status: ./scripts/kafka-status.sh
```

Troubleshooting:
- If neither Podman nor Docker is found, install one of them (see Prerequisites)
- If port 9092 is busy, stop conflicting services or change port in `compose.yml`
- On macOS with Podman: ensure podman machine is running (`podman machine start`)

## Step 3: Build the Application (1-2 minutes)

```bash
# Make gradlew executable (Unix/Mac)
chmod +x gradlew

# Build the project
./gradlew clean build

# The build should complete successfully
# Output: BUILD SUCCESSFUL in 15-30s
```

On Windows, use `gradlew.bat` instead:
```cmd
gradlew.bat clean build
```

## Step 4: Create Kafka Topics (30 seconds)

The application uses topics named by word length (3, 4, 5, ..., 10). Create them with the automated script:

```bash
# Create all required topics automatically
./scripts/create-topics.sh

# The script will:
# - Detect container runtime
# - Verify Kafka is running
# - Create topics 3-10
# - Display all topics
```

You should see output like:
```
========================================
Kafka Word Splitter - Topic Creation
========================================

Detected runtime: podman

Checking if Kafka is running...
✓ Kafka container is running

Creating topics 3-10...
✓ Created topic: 3
✓ Created topic: 4
✓ Created topic: 5
✓ Created topic: 6
✓ Created topic: 7
✓ Created topic: 8
✓ Created topic: 9
✓ Created topic: 10

All Kafka topics:
  - topic-3
  - topic-4
  - topic-5
  - topic-6
  - topic-7
  - topic-8
  - topic-9
  - topic-10

Total topics: 8
```

## Step 5: Run the Consumer (30 seconds)

Open a new terminal window and start a consumer:

```bash
cd kafka-word-splitter

# Run consumer for 5-letter words
java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar \
  org.example.ConsumerApp 5 output-5.txt
```

You should see:
```
INFO  Starting Kafka consumer for topic: 5
INFO  Consumer started successfully
INFO  Writing to file: output-5.txt
```

Leave this terminal running. The consumer is now waiting for messages.

## Step 6: Run the Producer (30 seconds)

Open another new terminal window and start a producer:

```bash
cd kafka-word-splitter

# Create a directory for the producer to watch
mkdir -p /tmp/kafka-watch

# Run producer
java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar \
  org.example.ProducerApp /tmp/kafka-watch
```

You should see:
```
INFO  Starting file watcher for directory: /tmp/kafka-watch
INFO  Producer started successfully
INFO  Watching for new files...
```

Leave this terminal running. The producer is now watching for new files.

## Step 7: See It Work! (30 seconds)

Now let's send some data through the system:

```bash
# In a third terminal, create a test file
echo "Hello world from Kafka system" > /tmp/kafka-watch/test1.txt
```

Watch what happens:

**In the Producer terminal**, you should see:
```
INFO  New file detected: test1.txt
INFO  Processing file: /tmp/kafka-watch/test1.txt
INFO  Sent word 'Hello' (length: 5) to topic 5
INFO  Sent word 'world' (length: 5) to topic 5
INFO  Sent word 'Kafka' (length: 5) to topic 5
INFO  File processed successfully
```

**In the Consumer terminal**, you should see:
```
INFO  Received word: Hello
INFO  Received word: world
INFO  Received word: Kafka
```

**Check the output file**:
```bash
cat output-5.txt
```

You should see:
```
Hello
world
Kafka
```

Success! The system is working end-to-end.

## What Just Happened?

1. Producer watched `/tmp/kafka-watch/` directory
2. When `test1.txt` appeared, it read the file
3. Split content into words: "Hello", "world", "from", "Kafka", "system"
4. Sent 5-letter words to topic "5": Hello, world, Kafka
5. Consumer subscribed to topic "5" received those words
6. Consumer wrote them to `output-5.txt`

Words with other lengths went to different topics (e.g., "from" went to topic "4", "system" went to topic "6").

## Try It Yourself

```bash
# Send more data
echo "The quick brown fox jumps" > /tmp/kafka-watch/test2.txt

# The producer will process it automatically
# Check output-5.txt for 5-letter words: quick, brown, jumps
cat output-5.txt
```

## Run Multiple Consumers

To see words of all lengths, start consumers for other topics:

```bash
# Terminal 1: Consumer for 3-letter words
java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar \
  org.example.ConsumerApp 3 output-3.txt

# Terminal 2: Consumer for 4-letter words
java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar \
  org.example.ConsumerApp 4 output-4.txt

# Or run all consumers in the background
for i in {3..10}; do
  java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar \
    org.example.ConsumerApp "$i" "output-$i.txt" > "consumer-$i.log" 2>&1 &
done
```

## Graceful Shutdown

When you're done testing:

1. **Stop Producer and Consumers**: Press `Ctrl+C` in each terminal
   - Applications will shut down gracefully
   - Resources will be cleaned up
   - Final messages will be flushed

2. **Stop Kafka Infrastructure**:
   ```bash
   ./scripts/stop-kafka.sh
   ```

   The script will gracefully stop Kafka and Zookeeper containers.

3. **Clean Up** (optional):
   ```bash
   # Remove test files
   rm -rf /tmp/kafka-watch
   rm output-*.txt
   ```

## Common Issues and Solutions

### Issue: "No container runtime found"
**Solution**: Install Podman or Docker
```bash
# macOS (Podman recommended)
brew install podman
podman machine init
podman machine start

# OR install Docker Desktop
# Download from https://www.docker.com/products/docker-desktop/
```

### Issue: "Port 9092 already in use"
**Solution**: Another Kafka instance is running
```bash
# Find what's using the port
lsof -i :9092

# Stop other Kafka instances or change port in compose.yml
```

### Issue: "Podman machine not running" (macOS)
**Solution**: Start the Podman machine
```bash
podman machine start
```

### Issue: "Topic not found"
**Solution**: Run the topic creation script
```bash
./scripts/create-topics.sh
```

### Issue: "No such file: kafka-word-splitter-1.0-SNAPSHOT-all.jar"
**Solution**: Build wasn't complete
```bash
./gradlew clean shadowJar
ls -lh build/libs/
```

### Issue: "Consumer not receiving messages"
**Solution**: Check infrastructure status
```bash
# Check if services are running
./scripts/kafka-status.sh

# Verify topics exist
# Producer sends to topics 3-10 (word length)
# Consumer must subscribe to correct topic number
```

### Issue: "Permission denied: gradlew" or script files
**Solution**: Make scripts executable
```bash
chmod +x gradlew
chmod +x start-kafka.sh
chmod +x scripts/*.sh
```

## Next Steps

Now that you have the basics working:

1. **Read the Architecture**: [ARCHITECTURE_REPORT.md](ARCHITECTURE_REPORT.md)
2. **Understand the Build**: [BUILD.md](BUILD.md)
3. **Learn About Shutdown**: [SHUTDOWN.md](SHUTDOWN.md)
4. **Explore the Code**: Check out the source in `src/main/java/org/example/`
5. **Contribute**: See [CONTRIBUTING.md](CONTRIBUTING.md)

## Quick Reference

### Start Everything
```bash
./start-kafka.sh               # Start Kafka infrastructure
./gradlew clean build          # Build application
./scripts/create-topics.sh     # Create required topics
```

### Check Status
```bash
./scripts/kafka-status.sh      # Check infrastructure health
```

### Run Producer
```bash
java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar \
  org.example.ProducerApp /path/to/watch
```

### Run Consumer
```bash
java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar \
  org.example.ConsumerApp <topic-number> <output-file>
```

### Stop Everything
```bash
# Ctrl+C for producer/consumers
./scripts/stop-kafka.sh        # Stop Kafka infrastructure
```

## Development Mode

For development, use Gradle directly:

```bash
# Run consumer
./gradlew run --args="3 output-3.txt"

# Build continuously
./gradlew build --continuous

# Run tests
./gradlew test

# Run quality checks
./gradlew check
```

## Need Help?

- Check [SUPPORT.md](SUPPORT.md) for getting help
- Review [BUILD.md](BUILD.md) for detailed build instructions
- See [README.md](README.md) for full documentation
- Open an [issue](https://github.com/strawberry-code/kafka-word-splitter/issues) if you find a bug

---

**Congratulations!** You now have Kafka Word Splitter running. Time to explore what else it can do!
