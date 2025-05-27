# Kafka-to-Kafka with Avro using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- Reads data from a Kafka topic using Confluent Avro
- Deserializes using Confluent Schema Registry
- Transforms the data using SQRL
- Writes enriched data to a new Kafka topic
- Automatically registers the output schema with the Schema Registry

---

## 🛠 Prerequisites

Ensure the following services are running locally:

- **Kafka** (Bootstrap servers: `localhost:9092`)
- **Confluent Schema Registry** (`http://localhost:8081`)
- **Docker**

You should have a topic in Kafka (`contact`) with data serialized in Avro using the Schema Registry.

---

## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:

```bash
docker run -it --rm \
  -p 8888:8888 \
  -v $PWD:/build \
  datasqrl/cmd:dev run -c package.json
```

## Generate Data
* Go to `data-generator` folder

Usage:

    python send_kafka_avro_records.py <schema.avsc> <data.jsonl> <topic> <broker> <schema-registry-url>

Example:

     python send_kafka_avro_records.py contact.avsc data.jsonl contact localhost:9092 http://localhost:8081

What it does:

- Reads newline-delimited JSON (.jsonl) file.
- Publishes each record as a Kafka message.
- For example, to load static test files to Kafka topics.

## Output
* You should see output topic created called enrichedcontact_avro with data in it