package org.example;

import java.time.Duration;

/**
 * Central configuration class for Kafka-related constants and configuration values.
 * This class contains all hardcoded values extracted from the service classes
 * to improve maintainability and configuration management.
 */
public final class KafkaConfig {

    // Kafka connection settings
    public static final String BOOTSTRAP_SERVERS = "localhost:9092";

    // Serialization settings
    public static final String STRING_SERIALIZER = "org.apache.kafka.common.serialization.StringSerializer";
    public static final String STRING_DESERIALIZER = "org.apache.kafka.common.serialization.StringDeserializer";

    // Consumer settings
    public static final Duration POLL_TIMEOUT = Duration.ofMillis(100);
    public static final String CONSUMER_GROUP_PREFIX = "consumer-group-";

    // Producer settings
    public static final int MAX_WORD_LENGTH = 10;

    // Executor service settings
    public static final Duration EXECUTOR_SHUTDOWN_TIMEOUT = Duration.ofSeconds(30);

    // Private constructor to prevent instantiation
    private KafkaConfig() {
        throw new UnsupportedOperationException("This is a utility class and cannot be instantiated");
    }
}
