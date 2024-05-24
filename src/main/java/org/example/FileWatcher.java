package org.example;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.*;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Watches a directory for new file creation events and delegates file processing
 * to the Kafka producer service.
 *
 * Supports graceful shutdown to stop watching without hanging.
 */
public class FileWatcher {
    private static final Logger logger = LoggerFactory.getLogger(FileWatcher.class);

    private final Path dir;
    private final KafkaProducerService producerService;
    private volatile boolean running = true;
    private final AtomicBoolean closed = new AtomicBoolean(false);
    private WatchService watchService;

    /**
     * Initializes the file watcher for a specific directory.
     *
     * @param dir the directory path to watch
     * @param producerService the Kafka producer service to process files
     * @throws IllegalArgumentException if dir or producerService is null or empty
     * @throws IllegalStateException if the directory does not exist or is not a directory
     */
    public FileWatcher(String dir, KafkaProducerService producerService) {
        if (dir == null || dir.trim().isEmpty()) {
            throw new IllegalArgumentException("Directory path cannot be null or empty");
        }
        if (producerService == null) {
            throw new IllegalArgumentException("Producer service cannot be null");
        }

        this.dir = Paths.get(dir);

        // Validate directory exists
        if (!Files.exists(this.dir)) {
            logger.error("Watch directory does not exist: {}", this.dir);
            throw new IllegalStateException("Watch directory does not exist: " + this.dir);
        }

        // Validate it's a directory
        if (!Files.isDirectory(this.dir)) {
            logger.error("Path is not a directory: {}", this.dir);
            throw new IllegalStateException("Path is not a directory: " + this.dir);
        }

        this.producerService = producerService;

        logger.info("FileWatcher initialized for directory: {}", dir);
    }

    /**
     * Starts watching the directory for file creation events.
     * Blocks until shutdown is requested via shutdown() method.
     */
    public void watch() {
        try {
            watchService = FileSystems.getDefault().newWatchService();
            dir.register(watchService, StandardWatchEventKinds.ENTRY_CREATE);

            logger.info("Started watching directory: {}", dir);

            while (running) {
                WatchKey key;
                try {
                    // Use poll instead of take to allow checking running flag periodically
                    key = watchService.poll(100, java.util.concurrent.TimeUnit.MILLISECONDS);
                    if (key == null) {
                        // No events, continue to check running flag
                        continue;
                    }
                } catch (InterruptedException e) {
                    logger.info("File watcher interrupted");
                    Thread.currentThread().interrupt();
                    break;
                }

                if (!running) {
                    logger.info("Shutdown requested, stopping file watch");
                    break;
                }

                for (WatchEvent<?> event : key.pollEvents()) {
                    WatchEvent.Kind<?> kind = event.kind();

                    if (kind == StandardWatchEventKinds.OVERFLOW) {
                        logger.warn("Watch event overflow occurred");
                        continue;
                    }

                    if (kind == StandardWatchEventKinds.ENTRY_CREATE) {
                        Path filePath = dir.resolve((Path) event.context());
                        logger.info("New file detected: {}", filePath);
                        producerService.processFile(filePath);
                    }
                }

                boolean valid = key.reset();
                if (!valid) {
                    logger.error("Watch key is no longer valid, stopping watcher");
                    break;
                }
            }

            logger.info("File watcher loop exited gracefully");

        } catch (IOException e) {
            logger.error("Error initializing file watcher", e);
        } finally {
            cleanup();
        }
    }

    /**
     * Initiates graceful shutdown of the file watcher.
     * Stops watching for new files and closes the watch service.
     *
     * This method is thread-safe and can be called from shutdown hooks.
     */
    public void shutdown() {
        if (closed.compareAndSet(false, true)) {
            logger.info("Initiating file watcher shutdown...");
            running = false;
        } else {
            logger.warn("Shutdown already initiated");
        }
    }

    /**
     * Performs cleanup of watch service resources.
     */
    private void cleanup() {
        if (watchService != null) {
            try {
                logger.info("Closing watch service...");
                watchService.close();
                logger.info("Watch service closed successfully");
            } catch (IOException e) {
                logger.error("Error closing watch service", e);
            }
        }
    }
}
