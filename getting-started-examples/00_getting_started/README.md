# DataSQRL Personal Examples

This repository contains a curated set of practical, beginner-friendly examples for learning and experimenting with [DataSQRL](https://github.com/DataSQRL/sqrl). Each example demonstrates a real-world data pipeline pattern using technologies like Kafka, Iceberg, Glue, and Schema Registry.

## 📁 Example Index

| Folder                                           | Description                                                                                            |
| ------------------------------------------------ |--------------------------------------------------------------------------------------------------------|
| **01\_kafka\_to\_console**                       | Reads from Kafka and outputs to console. Simple setup for basic Kafka ingestion testing.               |
| **02\_kafka\_to\_kafka**                         | Reads from one Kafka topic and writes to another. Useful for learning basic Kafka transformations.     |
| **03\_two\_streams\_kafka\_to\_kafka**           | Combines two Kafka topics, performs stream joins/enrichment, and writes to Kafka.                      |
| **04\_two\_streams\_external\_kafka\_to\_kafka** | Simulates a more decoupled version of multi-stream joins. Good for external integration scenarios.     |
| **05\_file\_iceberg\_test**                      | Writes data to local file-based Iceberg tables. Great for learning Iceberg without cloud dependencies. |
| **06\_external\_kafka\_iceberg\_test**           | Kafka to Iceberg using a local warehouse directory. Minimal config, good for staging/testing.          |
| **07\_external\_kafka\_iceberg\_glue\_test**     | Kafka to Iceberg using AWS Glue as catalog and S3 as storage.                                          |
| **08\_schema\_registry\_kafka\_to\_kafka**       | Kafka-to-Kafka pipeline using Confluent Schema Registry for Avro schema management.                    |

Each folder includes:

* `package.json`: Configuration for engines, connectors, and environment
* `.sqrl` script(s): The logic for the pipeline
* `data_generator/`: Input data generation scripts and sample files

---

## 🚀 Getting Started

### Prerequisites

* [Docker](https://docs.docker.com/get-docker/) installed
* Optional: Kafka and Schema Registry (locally or in cloud)
* For Glue/S3 integration: AWS CLI credentials (`~/.aws`) mounted in Docker

### Run Any Example

```bash
docker run -it --rm \
  -p 8888:8888 \
  -p 8081:8081 \
  -v $PWD:/build \
  datasqrl/cmd:dev run -c package.json
```

If using AWS or external services, extend with environment mounts:

```bash
docker run -it --rm \
  -p 8888:8888 \
  -p 8081:8081 \
  -v $PWD:/build \
  -v ~/.aws:/root/.aws \
  -e AWS_REGION=us-east-1 \
  -e S3_WAREHOUSE_PATH=s3://your-bucket/path/ \
  datasqrl/cmd:dev run -c package.json
```

### Compile Without Running

```bash
docker run -it --rm \
  -v $PWD:/build \
  datasqrl/cmd:dev compile -c package.json
```

---

## 🤔 Why These Examples?

These examples are designed to:

* Be self-contained and runnable out-of-the-box
* Good to get started with datasqrl
* Serve as a foundation for building your own DataSQRL pipelines

---

## 📚 Learn More

* 📘 [DataSQRL Docs](https://datasqrl.github.io/sqrl)
* 💻 [GitHub Repository](https://github.com/DataSQRL/sqrl)
* 💬 [Community Discord](https://docs.datasqrl.com/community/)

Feel free to fork and build on top of these examples!
