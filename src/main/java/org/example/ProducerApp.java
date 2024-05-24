package org.example;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.file.Files;
import java.nio.file.Paths;

/**
 * Main application for the Kafka word splitter producer.
 * Watches a directory for new text files, processes them, and publishes words to Kafka topics.
 * Each word is published to a topic named after its length.
 */
public class ProducerApp {
    private static final Logger logger = LoggerFactory.getLogger(ProducerApp.class);

    /**
     * Main entry point for the producer application.
     *
     * @param args command line arguments, expects one argument: the directory path to watch
     */
    public static void main(String[] args) {
        if (args.length < 1) {
            logger.error("Missing required argument: watch directory path");
            System.err.println("Usage: java ProducerApp <watch-directory>");
            System.exit(1);
        }

        String watchDir = args[0];

        // Validate watch directory
        if (watchDir == null || watchDir.trim().isEmpty()) {
            logger.error("Watch directory path cannot be null or empty");
            System.err.println("Error: Watch directory path cannot be null or empty");
            System.exit(1);
        }

        if (!Files.exists(Paths.get(watchDir))) {
            logger.error("Watch directory does not exist: {}", watchDir);
            System.err.println("Error: Watch directory does not exist: " + watchDir);
            System.exit(1);
        }

        if (!Files.isDirectory(Paths.get(watchDir))) {
            logger.error("Path is not a directory: {}", watchDir);
            System.err.println("Error: Path is not a directory: " + watchDir);
            System.exit(1);
        }

        logger.info("Starting Kafka Word Splitter Producer");
        logger.info("Watch directory: {}", watchDir);

        try {
            KafkaProducerService producerService = new KafkaProducerService();
            FileWatcher fileWatcher = new FileWatcher(watchDir, producerService);

            // Register shutdown hook for graceful termination
            // Shutdown sequence:
            // 1. Stop file watcher (no new files accepted)
            // 2. Shutdown producer service (finish in-flight tasks, close producer)
            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                logger.info("Shutdown signal received, initiating graceful shutdown...");

                try {
                    // Step 1: Stop accepting new files
                    logger.info("Stopping file watcher...");
                    fileWatcher.shutdown();

                    // Step 2: Shutdown producer (finish in-flight, close producer)
                    logger.info("Shutting down producer service...");
                    producerService.shutdown();

                    logger.info("Graceful shutdown completed successfully");
                } catch (Exception e) {
                    logger.error("Error during shutdown", e);
                }
            }, "producer-shutdown-hook"));

            logger.info("Shutdown hook registered");
            logger.info("Producer application initialized successfully");
            logger.info("Application started. Press Ctrl+C to stop gracefully.");

            // Start watching (blocks until shutdown)
            fileWatcher.watch();

            logger.info("File watcher stopped, application exiting");

        } catch (Exception e) {
            logger.error("Fatal error in producer application: {}", e.getMessage(), e);
            System.exit(1);
        }
    }
}
