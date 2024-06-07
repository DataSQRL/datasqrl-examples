#!/bin/bash
/opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --topic clickstream --partitions 1 --replication-factor 1
/opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --topic content --partitions 1 --replication-factor 1
exit 0;
