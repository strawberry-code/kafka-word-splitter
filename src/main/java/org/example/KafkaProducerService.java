package org.example;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Properties;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Service responsible for processing text files and publishing words to Kafka topics.
 * Words are split from files and published to topics based on word length.
 * Files are deleted after successful processing.
 *
 * Thread-safe shutdown mechanism ensures graceful termination.
 */
public class KafkaProducerService {
    private static final Logger logger = LoggerFactory.getLogger(KafkaProducerService.class);

    private final KafkaProducer<String, String> producer;
    private final ExecutorService executorService;
    private volatile boolean running = true;
    private final AtomicBoolean closed = new AtomicBoolean(false);

    /**
     * Initializes the Kafka producer service with default configuration.
     * Creates a single-threaded executor for asynchronous file processing.
     */
    public KafkaProducerService() {
        logger.info("Initializing Kafka producer service with bootstrap servers: {}", KafkaConfig.BOOTSTRAP_SERVERS);

        Properties props = new Properties();
        props.put("bootstrap.servers", KafkaConfig.BOOTSTRAP_SERVERS);
        props.put("key.serializer", KafkaConfig.STRING_SERIALIZER);
        props.put("value.serializer", KafkaConfig.STRING_SERIALIZER);

        this.producer = new KafkaProducer<>(props);
        this.executorService = Executors.newSingleThreadExecutor();

        logger.info("Kafka producer service initialized successfully");
    }

    /**
     * Processes a text file asynchronously by splitting its content into words
     * and publishing each word to a Kafka topic. The topic is determined by the word length.
     * Words longer than {} characters are filtered out.
     * The file is deleted after successful processing.
     *
     * @param filePath the path to the file to process
     * @throws IllegalArgumentException if filePath is null
     */
    public void processFile(Path filePath) {
        if (filePath == null) {
            throw new IllegalArgumentException("File path cannot be null");
        }

        if (!running) {
            logger.warn("Service is shutting down, rejecting file: {}", filePath);
            return;
        }

        logger.info("Scheduling file for processing: {}", filePath);

        executorService.execute(() -> {
            try {
                if (!running) {
                    logger.info("Shutdown in progress, skipping file: {}", filePath);
                    return;
                }

                logger.debug("Starting to process file: {}", filePath);

                if (!Files.exists(filePath)) {
                    logger.warn("File does not exist, skipping: {}", filePath);
                    return;
                }

                if (!Files.isRegularFile(filePath)) {
                    logger.warn("Path is not a regular file, skipping: {}", filePath);
                    return;
                }

                String content = Files.readString(filePath);
                logger.debug("Read file content, length: {} characters from file: {}", content.length(), filePath);

                long wordCount = Arrays.stream(content.split("\\s+"))
                        .filter(word -> !word.isEmpty())
                        .filter(word -> word.length() <= KafkaConfig.MAX_WORD_LENGTH)
                        .peek(word -> {
                            String topic = String.valueOf(word.length());
                            logger.debug("Publishing word '{}' to topic '{}'", word, topic);
                            producer.send(new ProducerRecord<>(topic, word));
                        })
                        .count();

                logger.info("Published {} words from file: {}", wordCount, filePath);

                // Delete file after successful processing
                logger.info("Deleting processed file: {}", filePath);
                Files.delete(filePath);
                logger.info("Successfully deleted file: {}", filePath);

            } catch (IOException e) {
                logger.error("Error processing file: {}. Error: {}", filePath, e.getMessage(), e);
            } catch (Exception e) {
                logger.error("Unexpected error processing file: {}. Error: {}", filePath, e.getMessage(), e);
            }
        });
    }

    /**
     * Initiates graceful shutdown of the producer service.
     * Shutdown sequence:
     * 1. Stop accepting new files (set running = false)
     * 2. Wait for in-flight processing (ExecutorService shutdown with timeout)
     * 3. Flush and close Kafka producer
     * 4. Log completion
     *
     * This method is thread-safe and can be called from shutdown hooks.
     * Does not throw checked exceptions to ensure compatibility with shutdown hooks.
     */
    public void shutdown() {
        if (closed.compareAndSet(false, true)) {
            logger.info("Initiating producer shutdown...");
            running = false;
            shutdownExecutor();
            closeProducer();
            logger.info("Producer shutdown completed");
        } else {
            logger.warn("Shutdown already initiated");
        }
    }

    /**
     * Shuts down the executor service gracefully with timeout.
     */
    private void shutdownExecutor() {
        if (executorService != null) {
            try {
                logger.info("Shutting down executor service...");
                executorService.shutdown();

                if (!executorService.awaitTermination(KafkaConfig.EXECUTOR_SHUTDOWN_TIMEOUT.getSeconds(), TimeUnit.SECONDS)) {
                    logger.warn("Executor service did not terminate within {} seconds, forcing shutdown",
                               KafkaConfig.EXECUTOR_SHUTDOWN_TIMEOUT.getSeconds());
                    executorService.shutdownNow();

                    if (!executorService.awaitTermination(10, TimeUnit.SECONDS)) {
                        logger.error("Executor service did not terminate after forced shutdown");
                    }
                } else {
                    logger.info("Executor service shut down successfully");
                }
            } catch (InterruptedException e) {
                logger.error("Interrupted while waiting for executor shutdown", e);
                executorService.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }
    }

    /**
     * Closes the Kafka producer, flushing any pending messages.
     */
    private void closeProducer() {
        if (producer != null) {
            try {
                logger.info("Flushing and closing Kafka producer...");
                producer.flush();
                producer.close();
                logger.info("Kafka producer closed successfully");
            } catch (Exception e) {
                logger.error("Error closing Kafka producer", e);
            }
        }
    }
}
