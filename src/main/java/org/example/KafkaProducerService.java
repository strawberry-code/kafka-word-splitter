package org.example;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Properties;
import java.util.concurrent.Executors;

public class KafkaProducerService {
    private final KafkaProducer<String, String> producer;

    public KafkaProducerService() {
        Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        this.producer = new KafkaProducer<>(props);
    }

    public void processFile(Path filePath) {
        Executors.newSingleThreadExecutor().execute(() -> {
            try {
                String content = Files.readString(filePath);
                System.out.println("kafka");
                Arrays.stream(content.split("\\s+"))
                        .filter(word -> word.length() <= 10)
                        .forEach(word -> {
                            System.out.println("lal");
                            System.out.println(word);
                            String topic = String.valueOf(word.length());
                            producer.send(new ProducerRecord<>(topic, word));
                        });
                Files.delete(filePath);  // Elimina il file dopo aver completato l'elaborazione
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }
}
