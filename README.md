# Kafka File Processor

Questo progetto dimostra l'uso di Apache Kafka in un ambiente distribuito utilizzando Docker. Il progetto è composto da diversi producer e consumer che interagiscono tramite Kafka per elaborare file di testo.

## Descrizione

Il progetto consiste in:
- **Producer**: Monitora una directory specifica per nuovi file. Quando un nuovo file viene rilevato, il producer legge il file, divide il contenuto in parole e invia ogni parola come un messaggio a Kafka. Il topic del messaggio è determinato dalla lunghezza della parola (ad esempio, le parole di 3 caratteri vanno al topic "3").
- **Consumer**: Ogni consumer è associato a un topic specifico e scrive le parole ricevute in un file di output. Ogni consumer osserva solo un topic.

## Prerequisiti

- Docker
- Docker Compose
- Java 17
- Gradle

## Configurazione del Progetto

### Step 1: Clona il repository

```sh
git clone https://github.com/username/kafka-file-processor.git
cd kafka-file-processor
```

### Step 2: Configura Kafka con Docker

Crea un file `docker-compose.yml` con il seguente contenuto:

```yaml
version: '2'
services:
  zookeeper:
    image: wurstmeister/zookeeper:3.4.6
    ports:
     - "2181:2181"
  
  kafka:
    image: wurstmeister/kafka:2.13-2.7.0
    ports:
     - "9092:9092"
    expose:
     - "9093"
    environment:
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
    volumes:
     - /var/run/docker.sock:/var/run/docker.sock
```

### Step 3: Avvia Kafka e Zookeeper

```sh
docker-compose up -d
```

### Step 4: Crea i topic Kafka

Accedi al container Kafka e crea i topic:

```sh
docker ps
docker exec -it <kafka_container_id> /bin/sh
for i in {3..10}; do kafka-topics.sh --create --topic "$i" --bootstrap-server localhost:9092; done
```

### Step 5: Compila il progetto

```sh
./gradlew clean build
./gradlew shadowJar
```

## Esecuzione del Progetto

### Avvia i producer

```sh
java -jar build/libs/kafka-file-processor-1.0-SNAPSHOT.jar com.example.ProducerApp /path/to/watch1
java -jar build/libs/kafka-file-processor-1.0-SNAPSHOT.jar com.example.ProducerApp /path/to/watch2
java -jar build/libs/kafka-file-processor-1.0-SNAPSHOT.jar com.example.ProducerApp /path/to/watch3
java -jar build/libs/kafka-file-processor-1.0-SNAPSHOT.jar com.example.ProducerApp /path/to/watch4
java -jar build/libs/kafka-file-processor-1.0-SNAPSHOT.jar com.example.ProducerApp /path/to/watch5
```

### Avvia i consumer

```sh
for i in {3..10}; do java -jar build/libs/kafka-file-processor-1.0-SNAPSHOT.jar com.example.ConsumerApp "$i" /path/to/output"$i".txt; done
```

## Verifica

Puoi verificare che Kafka sia accessibile all'indirizzo `localhost:9092` utilizzando i comandi `telnet` o `nc`:

```sh
telnet localhost 9092
# oppure
nc -zv localhost 9092
```

## Contribuire

Le richieste di pull sono benvenute. Per modifiche importanti, apri prima un problema per discutere ciò che vorresti cambiare.

Assicurati di aggiornare i test se necessario.

## Licenza

[MIT](https://choosealicense.com/licenses/mit/)