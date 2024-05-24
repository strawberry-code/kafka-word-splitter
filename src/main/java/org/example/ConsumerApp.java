package org.example;

public class ConsumerApp {
    public static void main(String[] args) {
        String topic = args[0];
        String outputFile = args[1];
        KafkaConsumerService consumerService = new KafkaConsumerService(topic, outputFile);
        consumerService.consume();
    }
}