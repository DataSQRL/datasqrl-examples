# Kafka Source Data

To use Kafka as the source for the transactions and merchant rewards, you need to:

1. Create the following additional topics in the kafka cluster: `transaction`, `merchantreward`, and `customerreward`. You can do this by adding the topic creation statements to the kafka/Dockerfile in the `deploy` folder manually before running docker compose up (add before the last line):
```
    && echo '/opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --topic transaction --partitions 1 --replication-factor 1' >> /opt/bitnami/scripts/kafka/create-topics.sh \
    && echo '/opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --topic merchantreward --partitions 1 --replication-factor 1' >> /opt/bitnami/scripts/kafka/create-topics.sh \
    && echo '/opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --topic customerreward --partitions 1 --replication-factor 1' >> /opt/bitnami/scripts/kafka/create-topics.sh \
```
2. Once the topics have been successfully created, load the data using the `load_data.py` script in the `creditcard-local` folder:
   1. `python3 load_data.py merchantReward.jsonl localhost:9094 merchantreward --msg 200`
   2. `python3 load_data.py transaction.jsonl localhost:9094 transaction --msg 50`
