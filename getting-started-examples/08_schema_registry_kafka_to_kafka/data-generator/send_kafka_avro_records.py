import json
import sys
from confluent_kafka.avro import AvroProducer, loads


def load_avro_schema_from_file(file_path):
    with open(file_path, "r") as f:
        return loads(f.read())  # Parses the schema correctly


def produce_avro_messages(jsonl_path, schema_file, topic, bootstrap_servers, schema_registry_url):
    value_schema = load_avro_schema_from_file(schema_file)

    avro_producer = AvroProducer({
        'bootstrap.servers': bootstrap_servers,
        'schema.registry.url': schema_registry_url
    }, default_value_schema=value_schema)

    with open(jsonl_path, "r") as f:
        for line in f:
            record = json.loads(line.strip())
            avro_producer.produce(topic=topic, value=record)
            print(f"Sent: {record}")

    avro_producer.flush()
    print("All messages sent.")


if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("Usage: python send_kafka_avro_records.py <schema.avsc> <data.jsonl> <topic> <broker> <schema-registry-url>")
        sys.exit(1)

    schema_file = sys.argv[1]
    data_file = sys.argv[2]
    topic_name = sys.argv[3]
    kafka_broker = sys.argv[4]
    registry_url = sys.argv[5]

    produce_avro_messages(data_file, schema_file, topic_name, kafka_broker, registry_url)
