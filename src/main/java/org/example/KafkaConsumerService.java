package org.example;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Collections;
import java.util.Properties;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Service responsible for consuming messages from a Kafka topic and writing them to a file.
 * Each consumed message is appended to the specified output file with a newline.
 * The consumer runs in an infinite loop until shutdown is requested.
 */
public class KafkaConsumerService {
    private static final Logger logger = LoggerFactory.getLogger(KafkaConsumerService.class);

    private final KafkaConsumer<String, String> consumer;
    private final String outputFile;
    private volatile boolean running = true;
    private final AtomicBoolean closed = new AtomicBoolean(false);

    /**
     * Initializes the Kafka consumer service for a specific topic and output file.
     *
     * @param topic the Kafka topic to consume from
     * @param outputFile the path to the output file where messages will be written
     * @throws IllegalArgumentException if topic or outputFile is null or empty
     * @throws IllegalStateException if the output directory does not exist
     */
    public KafkaConsumerService(String topic, String outputFile) {
        if (topic == null || topic.trim().isEmpty()) {
            throw new IllegalArgumentException("Topic cannot be null or empty");
        }
        if (outputFile == null || outputFile.trim().isEmpty()) {
            throw new IllegalArgumentException("Output file path cannot be null or empty");
        }

        logger.info("Initializing Kafka consumer service for topic: {}, output file: {}", topic, outputFile);

        // Validate output directory exists
        Path outputPath = Paths.get(outputFile);
        Path parentDir = outputPath.getParent();
        if (parentDir != null && !Files.exists(parentDir)) {
            logger.error("Output directory does not exist: {}", parentDir);
            throw new IllegalStateException("Output directory does not exist: " + parentDir);
        }

        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, KafkaConfig.BOOTSTRAP_SERVERS);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, KafkaConfig.CONSUMER_GROUP_PREFIX + topic);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, KafkaConfig.STRING_DESERIALIZER);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, KafkaConfig.STRING_DESERIALIZER);
        this.consumer = new KafkaConsumer<>(props);
        this.consumer.subscribe(Collections.singletonList(topic));
        this.outputFile = outputFile;

        logger.info("Kafka consumer service initialized successfully");
    }

    /**
     * Starts consuming messages from the subscribed topic and writing them to the output file.
     * This method runs in an infinite loop until shutdown is requested.
     * Messages are appended to the output file with a newline after each message.
     * The consumer is automatically closed when the loop exits.
     */
    public void consume() {
        logger.info("Starting consumer loop, writing to: {}", outputFile);
        long messageCount = 0;

        try {
            while (running) {
                ConsumerRecords<String, String> records = consumer.poll(KafkaConfig.POLL_TIMEOUT);

                if (!records.isEmpty()) {
                    logger.debug("Polled {} records from Kafka", records.count());

                    for (ConsumerRecord<String, String> record : records) {
                        if (!running) {
                            logger.info("Shutdown requested, stopping record processing");
                            break;
                        }

                        logger.debug("Received message - topic: {}, partition: {}, offset: {}, value: {}",
                                record.topic(), record.partition(), record.offset(), record.value());

                        Files.writeString(
                                Paths.get(outputFile),
                                record.value() + "\n",
                                StandardOpenOption.CREATE,
                                StandardOpenOption.APPEND
                        );

                        messageCount++;
                    }

                    logger.info("Wrote {} messages to file, total messages processed: {}", records.count(), messageCount);
                }
            }
            logger.info("Consumer loop exited gracefully, total messages processed: {}", messageCount);
        } catch (IOException e) {
            logger.error("Error writing to output file: {}. Error: {}", outputFile, e.getMessage(), e);
            throw new RuntimeException("Failed to write to output file", e);
        } catch (Exception e) {
            logger.error("Unexpected error during message consumption. Error: {}", e.getMessage(), e);
            throw new RuntimeException("Consumer failed", e);
        } finally {
            cleanup();
        }
    }

    /**
     * Initiates graceful shutdown of the consumer service.
     * This method is thread-safe and can be called from shutdown hooks.
     */
    public void shutdown() {
        if (closed.compareAndSet(false, true)) {
            logger.info("Initiating consumer shutdown...");
            running = false;
        } else {
            logger.warn("Shutdown already initiated");
        }
    }

    /**
     * Performs cleanup of resources in the correct order.
     */
    private void cleanup() {
        if (consumer != null) {
            try {
                logger.info("Closing Kafka consumer...");
                consumer.close();
                logger.info("Kafka consumer closed successfully");
            } catch (Exception e) {
                logger.error("Error closing Kafka consumer", e);
            }
        }
    }
}