package org.example;

import java.io.IOException;
import java.nio.file.*;

public class FileWatcher {
    private final Path dir;
    private final KafkaProducerService producerService;

    public FileWatcher(String dir, KafkaProducerService producerService) {
        this.dir = Paths.get(dir);
        this.producerService = producerService;
    }

    public void watch() {
        try (WatchService watchService = FileSystems.getDefault().newWatchService()) {
            dir.register(watchService, StandardWatchEventKinds.ENTRY_CREATE);
            while (true) {
                WatchKey key = watchService.take();
                for (WatchEvent<?> event : key.pollEvents()) {
                    WatchEvent.Kind<?> kind = event.kind();
                    if (kind == StandardWatchEventKinds.ENTRY_CREATE) {
                        Path filePath = dir.resolve((Path) event.context());
                        producerService.processFile(filePath);
                    }
                }
                key.reset();
            }
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
