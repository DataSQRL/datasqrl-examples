# Getting Started Examples

- **Builds:** seven small real-time pipelines, each showing one connector pattern, from Kafka to console up to Kafka to Iceberg on AWS Glue.
- **Shows:** Kafka · Iceberg · AWS Glue
- **Built with:** SQRL compiled to Flink, Kafka, Postgres, the DataSQRL API server, and Iceberg.

This folder contains a curated set of practical, beginner-friendly examples for learning and experimenting with [DataSQRL](https://github.com/DataSQRL/sqrl).
Each example demonstrates a real-world data pipeline pattern using technologies like Kafka, Iceberg, Glue, and Schema Registry.

## 📁 Example Index

| Folder                                                                            | Description                                                                                            |
|-----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| [**01\_kafka\_to\_console**](./01_kafka_to_console)                               | Reads from Kafka and outputs to console. Simple setup for basic Kafka ingestion testing.               |
| [**02\_kafka\_to\_kafka**](./02_kafka_to_kafka)                                   | Reads from one Kafka topic and writes to another. Useful for learning basic Kafka transformations.     |
| [**03\_kafka\_join**](./03_kafka_join)                                            | Combines two Kafka topics, performs stream joins/enrichment, and writes to Kafka.                      |
| [**04\_file\_to\_iceberg\_test**](./04_file_to_iceberg_test)                      | Writes data to local file-based Iceberg tables. Great for learning Iceberg without cloud dependencies. |
| [**05\_external\_kafka\_iceberg\_test**](./05_kafka_to_iceberg_local_test)        | Kafka to Iceberg using a local warehouse directory. Minimal config, good for staging/testing.          |
| [**06\_kafka\_iceberg\_glue\_test**](./06_kafka_to_iceberg_glue_test)             | Kafka to Iceberg using AWS Glue as catalog and S3 as storage.                                          |
| [**07\_schema\_registry\_kafka\_to\_kafka**](./07_schema_registry_kafka_to_kafka) | Kafka-to-Kafka pipeline using Confluent Schema Registry for Avro schema management.                    |

Each folder includes:

* `package.json`: Configuration for engines, connectors, and environment
* `.sqrl` script(s): The logic for the pipeline
* `data_generator/`: Input data generation scripts and sample files

---

## 🚀 Getting Started

### Prerequisites

* [Docker](https://docs.docker.com/get-docker/) installed
* Optional: Kafka and Schema Registry (locally or in cloud)
* For Glue/S3 integration: AWS CLI access key

### Run Any Example

```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 \
  -v $PWD:/workspace \
  datasqrl/cmd:latest run package.json
```

Example 07 reads from your own Kafka and Schema Registry on ports 9092 and 8081, so leave out
`-p 8081:8081 -p 9092:9092` there; its README has the command.

#### Persistent Data

To preserve the internally persisted data (for Postgres, Redpanda, and Flink) after the Docker container
stopped running, extend with `/data` mount:

```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 \
  -v $PWD:/workspace \
  -v $PWD/data:/data \
  datasqrl/cmd:latest run package.json
```

#### Mount External Services

If using AWS pass the necessary environment variables defined by the AWS SDK::

```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 \
  -v $PWD:/workspace \
  -e AWS_ACCESS_KEY_ID="<my-access-key>" \
  -e AWS_SECRET_ACCESS_KEY="<my-secret-key" \
  -e AWS_REGION="<my-region>" \
  datasqrl/cmd:latest run package.json
```

### Compile Without Running

```bash
docker run --rm \
  -v $PWD:/workspace \
  datasqrl/cmd:latest compile package.json
```

---

## 🤔 Why These Examples?

These examples are designed to:

* Be self-contained and runnable out-of-the-box
* Good to get started with DataSQRL
* Serve as a foundation for building your own DataSQRL pipelines

---

## 📚 Learn More

* 📘 [DataSQRL Docs](https://docs.datasqrl.com)
* 💻 [GitHub Repository](https://github.com/DataSQRL/sqrl)
* 💬 [Community Discord](https://docs.datasqrl.com/community/)

Feel free to fork and build on top of these examples!


## Build this with the DataSQRL plugin

Install the [DataSQRL plugin](https://github.com/DataSQRL/datasqrl-plugin) in Claude Code, Codex, Cursor, or Copilot, then paste this prompt:

```text
Build a DataSQRL pipeline that reads JSON events from a Kafka topic, deduplicates them by id,
and writes them to an Iceberg table on S3 with AWS Glue as the catalog.
```
