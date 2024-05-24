package org.example;

public class ProducerApp {
    public static void main(String[] args) {
        String watchDir = args[0];
        System.out.println("lol");
        KafkaProducerService producerService = new KafkaProducerService();
        FileWatcher fileWatcher = new FileWatcher(watchDir, producerService);
        fileWatcher.watch();
    }
}
