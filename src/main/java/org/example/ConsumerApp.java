package org.example;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Main application for the Kafka word splitter consumer.
 * Consumes messages from a Kafka topic and writes them to an output file.
 * Each consumed message is appended to the file with a newline.
 */
public class ConsumerApp {
    private static final Logger logger = LoggerFactory.getLogger(ConsumerApp.class);

    /**
     * Main entry point for the consumer application.
     *
     * @param args command line arguments, expects two arguments:
     *             1. Kafka topic name to consume from
     *             2. Output file path where messages will be written
     */
    public static void main(String[] args) {
        if (args.length < 2) {
            logger.error("Missing required arguments: topic and output file path");
            System.err.println("Usage: java ConsumerApp <topic> <output-file>");
            System.exit(1);
        }

        String topic = args[0];
        String outputFile = args[1];

        // Validate topic
        if (topic == null || topic.trim().isEmpty()) {
            logger.error("Topic name cannot be null or empty");
            System.err.println("Error: Topic name cannot be null or empty");
            System.exit(1);
        }

        // Validate output file path
        if (outputFile == null || outputFile.trim().isEmpty()) {
            logger.error("Output file path cannot be null or empty");
            System.err.println("Error: Output file path cannot be null or empty");
            System.exit(1);
        }

        // Validate output directory exists
        Path outputPath = Paths.get(outputFile);
        Path parentDir = outputPath.getParent();
        if (parentDir != null && !Files.exists(parentDir)) {
            logger.error("Output directory does not exist: {}", parentDir);
            System.err.println("Error: Output directory does not exist: " + parentDir);
            System.exit(1);
        }

        logger.info("Starting Kafka Word Splitter Consumer");
        logger.info("Topic: {}", topic);
        logger.info("Output file: {}", outputFile);

        try {
            KafkaConsumerService consumerService = new KafkaConsumerService(topic, outputFile);

            // Register shutdown hook for graceful termination
            // Shutdown sequence:
            // 1. Stop polling (set running = false)
            // 2. Finish processing current batch
            // 3. Close Kafka consumer
            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                logger.info("Shutdown signal received, initiating graceful shutdown...");

                try {
                    consumerService.shutdown();
                    logger.info("Graceful shutdown completed successfully");
                } catch (Exception e) {
                    logger.error("Error during shutdown", e);
                }
            }, "consumer-shutdown-hook"));

            logger.info("Shutdown hook registered");
            logger.info("Consumer application initialized successfully");
            logger.info("Application started. Press Ctrl+C to stop gracefully.");

            // Start consuming (blocks until shutdown)
            consumerService.consume();

            logger.info("Consumer stopped, application exiting");

        } catch (Exception e) {
            logger.error("Fatal error in consumer application: {}", e.getMessage(), e);
            System.exit(1);
        }
    }
}
