# Pass Kafka Container ID as first argument
docker exec -it $1 /bin/sh

# Create Kafka topics inside Kafka Docker
kafka-topics.sh --create --topic "1" --bootstrap-server localhost:9092
kafka-topics.sh --create --topic "2" --bootstrap-server localhost:9092
kafka-topics.sh --create --topic "3" --bootstrap-server localhost:9092
kafka-topics.sh --create --topic "4" --bootstrap-server localhost:9092
kafka-topics.sh --create --topic "5" --bootstrap-server localhost:9092
kafka-topics.sh --create --topic "6" --bootstrap-server localhost:9092
kafka-topics.sh --create --topic "7" --bootstrap-server localhost:9092
kafka-topics.sh --create --topic "8" --bootstrap-server localhost:9092
kafka-topics.sh --create --topic "9" --bootstrap-server localhost:9092
kafka-topics.sh --create --topic "10" --bootstrap-server localhost:9092

# Exit Docker container and move to you workspace environment
for i in {1..10}; do java -cp $HOME/Desktop/myzoo/kafka-word-splitter-1.0-SNAPSHOT.jar org.example.ConsumerApp "$i" $HOME/Desktop/myzoo/consumers"$i".txt; done

java -cp $HOME/Desktop/myzoo/kafka-word-splitter-1.0-SNAPSHOT.jar org.example.ConsumerApp "3" $HOME/Desktop/myzoo/consumers3.txt

java -jar $HOME/Desktop/myzoo/kafka-word-splitter-1.0-SNAPSHOT.jar com.example.ProducerApp $HOME/Desktop/myzoo/producers/1
java -jar $HOME/Desktop/myzoo/kafka-word-splitter-1.0-SNAPSHOT.jar com.example.ProducerApp $HOME/Desktop/myzoo/producers/2
java -jar $HOME/Desktop/myzoo/kafka-word-splitter-1.0-SNAPSHOT.jar com.example.ProducerApp $HOME/Desktop/myzoo/producers/3
java -jar $HOME/Desktop/myzoo/kafka-word-splitter-1.0-SNAPSHOT.jar com.example.ProducerApp $HOME/Desktop/myzoo/producers/4
