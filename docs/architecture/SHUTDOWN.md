# Graceful Shutdown Documentation

## Overview

This application implements comprehensive graceful shutdown mechanisms across all services to ensure:
- No data loss during shutdown
- Proper resource cleanup
- No hanging threads or connections
- Clean exit on SIGTERM/SIGINT (Ctrl+C)

## Architecture Overview

The application consists of two main components:

1. **Producer Application** - Watches for files and publishes words to Kafka
2. **Consumer Application** - Consumes words from Kafka and writes to output file

Both applications implement graceful shutdown via JVM shutdown hooks.

---

## Producer Application Shutdown Sequence

### Components Involved
- `ProducerApp` - Main application with shutdown hook
- `FileWatcher` - Directory monitoring service
- `KafkaProducerService` - Kafka producer and file processor
- `ExecutorService` - Async task executor

### Shutdown Flow

```
SIGTERM/SIGINT received
    |
    v
ProducerApp shutdown hook triggered
    |
    +---> 1. FileWatcher.shutdown()
    |        - Set running = false
    |        - Stop accepting new file events
    |        - Exit watch loop
    |        - Close WatchService
    |
    +---> 2. KafkaProducerService.shutdown()
             |
             +---> 2a. Stop accepting new tasks
             |     - Set running = false
             |     - Reject new processFile() calls
             |
             +---> 2b. Shutdown ExecutorService
             |     - Call executorService.shutdown()
             |     - Wait up to 30 seconds for tasks to complete
             |     - Force shutdown if timeout exceeded
             |
             +---> 2c. Close Kafka Producer
                   - Flush pending messages
                   - Close producer connection
                   - Log completion
```

### Timeouts

- **ExecutorService graceful shutdown**: 30 seconds (configurable in `KafkaConfig.EXECUTOR_SHUTDOWN_TIMEOUT`)
- **ExecutorService forced shutdown**: 10 seconds
- **FileWatcher poll interval**: 100ms (allows checking shutdown flag)

### Thread Safety

- `volatile boolean running` - Ensures visibility across threads
- `AtomicBoolean closed` - Prevents duplicate shutdown calls
- Synchronized state checks prevent race conditions

---

## Consumer Application Shutdown Sequence

### Components Involved
- `ConsumerApp` - Main application with shutdown hook
- `KafkaConsumerService` - Kafka consumer and file writer

### Shutdown Flow

```
SIGTERM/SIGINT received
    |
    v
ConsumerApp shutdown hook triggered
    |
    v
KafkaConsumerService.shutdown()
    |
    +---> 1. Set running = false
    |        - Consumer poll loop checks this flag
    |        - Completes current batch processing
    |
    +---> 2. Exit consume loop
    |        - while(running) exits gracefully
    |
    +---> 3. Close Kafka Consumer
             - Cleanup in finally block
             - Commit offsets
             - Close consumer connection
             - Log completion
```

### Timeouts

- **Poll timeout**: 100ms (configurable in `KafkaConfig.POLL_TIMEOUT`)
- Allows frequent checks of the `running` flag

### Thread Safety

- `volatile boolean running` - Ensures visibility across threads
- `AtomicBoolean closed` - Prevents duplicate shutdown calls
- Consumer poll loop checks flag after each batch

---

## Key Design Decisions

### 1. Volatile Boolean for Running State

```java
private volatile boolean running = true;
```

**Why:** Ensures that changes to the running flag are immediately visible to all threads without requiring explicit synchronization.

### 2. AtomicBoolean for Shutdown Coordination

```java
private final AtomicBoolean closed = new AtomicBoolean(false);

public void shutdown() {
    if (closed.compareAndSet(false, true)) {
        // Shutdown logic only runs once
    }
}
```

**Why:** Prevents duplicate shutdown attempts if shutdown() is called multiple times (e.g., by both shutdown hook and explicit call).

### 3. No Checked Exceptions in Shutdown Methods

```java
public void shutdown() {  // No throws clause
    try {
        // Cleanup logic
    } catch (Exception e) {
        logger.error("Error during shutdown", e);
    }
}
```

**Why:** Shutdown hooks cannot throw checked exceptions. Catching all exceptions ensures one component's failure doesn't prevent others from cleaning up.

### 4. Poll Instead of Take in Blocking Operations

**FileWatcher:**
```java
// Use poll with timeout instead of take()
key = watchService.poll(100, TimeUnit.MILLISECONDS);
```

**KafkaConsumerService:**
```java
// Already uses poll with timeout
records = consumer.poll(Duration.ofMillis(100));
```

**Why:** Allows periodic checking of the `running` flag, preventing infinite blocking that would prevent graceful shutdown.

### 5. Cleanup Order

**Producer:**
1. Stop accepting new work (FileWatcher)
2. Wait for in-flight work (ExecutorService)
3. Close connections (KafkaProducer)

**Consumer:**
1. Stop polling (set running = false)
2. Finish current batch
3. Close consumer (commit offsets, close connection)

**Why:** Ensures no data loss. Work is completed before connections are closed.

---

## Testing Shutdown

### Producer Application

```bash
# Start producer
./gradlew run --args="/path/to/watch/dir"

# Add a file to trigger processing
echo "test words" > /path/to/watch/dir/test.txt

# Send shutdown signal
# Press Ctrl+C or send SIGTERM

# Expected log output:
# INFO  Shutdown signal received, initiating graceful shutdown...
# INFO  Stopping file watcher...
# INFO  Initiating file watcher shutdown...
# INFO  Closing watch service...
# INFO  Watch service closed successfully
# INFO  Shutting down producer service...
# INFO  Initiating producer shutdown...
# INFO  Shutting down executor service...
# INFO  Executor service shut down successfully
# INFO  Flushing and closing Kafka producer...
# INFO  Kafka producer closed successfully
# INFO  Producer shutdown completed
# INFO  Graceful shutdown completed successfully
```

### Consumer Application

```bash
# Start consumer
./gradlew run --args="5 /path/to/output.txt"

# Send shutdown signal
# Press Ctrl+C or send SIGTERM

# Expected log output:
# INFO  Shutdown signal received, initiating graceful shutdown...
# INFO  Initiating consumer shutdown...
# INFO  Consumer loop exited gracefully
# INFO  Closing Kafka consumer...
# INFO  Kafka consumer closed successfully
# INFO  Graceful shutdown completed successfully
```

### Verification

After shutdown:
1. **No hanging processes** - Application exits cleanly
2. **No thread leaks** - All threads terminated
3. **No connection leaks** - Kafka connections closed
4. **No data loss** - In-flight messages processed
5. **Clean logs** - Shutdown logged at each stage

---

## Troubleshooting

### Application Hangs on Shutdown

**Possible Causes:**
1. ExecutorService tasks not completing within timeout
2. Kafka producer has pending messages that won't send
3. Watch service blocking indefinitely

**Solutions:**
1. Check executor shutdown timeout in `KafkaConfig.EXECUTOR_SHUTDOWN_TIMEOUT`
2. Ensure Kafka broker is reachable
3. Review logs for errors during shutdown

### "Shutdown already initiated" Warning

**Cause:** `shutdown()` called multiple times

**Impact:** None - this is expected behavior and prevents duplicate cleanup

**Solution:** No action needed - this is normal

### Interrupted Exception During Shutdown

**Cause:** Thread interrupted while waiting for executor termination

**Impact:** Executor forced to shutdown immediately

**Solution:** Review timeout settings if this occurs frequently

---

## Configuration

### Timeouts (KafkaConfig.java)

```java
// Poll timeout for consumer
public static final Duration POLL_TIMEOUT = Duration.ofMillis(100);

// Executor shutdown timeout for producer
public static final Duration EXECUTOR_SHUTDOWN_TIMEOUT = Duration.ofSeconds(30);
```

### Customization

To adjust shutdown behavior:

1. **Increase executor timeout** - If file processing takes longer
2. **Decrease poll timeout** - For faster shutdown response (at cost of CPU)
3. **Add custom cleanup** - Override cleanup() methods in services

---

## Production Recommendations

### 1. Monitoring

Monitor these metrics during shutdown:
- Shutdown duration
- In-flight task count
- Pending Kafka messages
- Thread count

### 2. Graceful Restart

When restarting:
```bash
# Send SIGTERM, wait for clean exit
kill -TERM <pid>
sleep 5

# Verify process exited
ps aux | grep ProducerApp

# Restart
./gradlew run --args="..."
```

### 3. Docker/Kubernetes

Ensure SIGTERM is properly forwarded:
- Set appropriate `terminationGracePeriodSeconds` in Kubernetes
- Use `STOPSIGNAL SIGTERM` in Dockerfile
- Avoid using `kill -9` (SIGKILL) which bypasses shutdown hooks

### 4. Health Checks

During shutdown:
- Health checks should fail immediately after shutdown initiated
- Readiness probes should report not-ready
- Liveness probes should still pass until process exits

---

## Code Examples

### Shutdown Hook Pattern

```java
Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    logger.info("Shutdown signal received, initiating graceful shutdown...");

    try {
        // Cleanup in correct order
        service1.shutdown();
        service2.shutdown();

        logger.info("Graceful shutdown completed successfully");
    } catch (Exception e) {
        logger.error("Error during shutdown", e);
    }
}, "shutdown-hook-name"));
```

### Thread-Safe Shutdown Method

```java
private volatile boolean running = true;
private final AtomicBoolean closed = new AtomicBoolean(false);

public void shutdown() {
    if (closed.compareAndSet(false, true)) {
        logger.info("Initiating shutdown...");
        running = false;
        cleanup();
        logger.info("Shutdown completed");
    } else {
        logger.warn("Shutdown already initiated");
    }
}
```

### Controlled Loop Pattern

```java
while (running) {
    // Use poll with timeout, not blocking take()
    Item item = queue.poll(100, TimeUnit.MILLISECONDS);

    if (item == null) {
        continue; // Check running flag
    }

    if (!running) {
        logger.info("Shutdown requested, stopping processing");
        break;
    }

    processItem(item);
}
```

---

## Summary

This implementation provides:

1. **Graceful Shutdown** - Clean exit on SIGTERM/SIGINT
2. **No Data Loss** - In-flight work completed before exit
3. **Proper Cleanup** - All resources closed in correct order
4. **Thread Safety** - Volatile flags and atomic operations
5. **Production Ready** - Timeouts, logging, error handling
6. **Testable** - Can verify shutdown behavior
7. **Maintainable** - Clear separation of concerns

The shutdown mechanism ensures production stability and prevents resource leaks, thread leaks, and data loss during application termination.
