import json
import sys
from kafka import KafkaProducer
from fastavro import parse_schema, schemaless_writer
from io import BytesIO

def load_avro_schema(avsc_path):
    with open(avsc_path, "r") as f:
        return parse_schema(json.load(f))

def produce_avro_messages(jsonl_path, schema, topic, bootstrap_servers):
    producer = KafkaProducer(bootstrap_servers=bootstrap_servers)

    with open(jsonl_path, "r") as f:
        for line in f:
            record = json.loads(line.strip())
            buf = BytesIO()
            schemaless_writer(buf, schema, record)
            producer.send(topic, buf.getvalue())
            print(f"Sent: {record}")

    producer.flush()
    producer.close()
    print("Done sending all messages.")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python send_kafka_avro_records.py <schema.avsc> <data.jsonl> <kafka_topic> <localhost:9092>")
        sys.exit(1)

    avsc_file = sys.argv[1]
    jsonl_file = sys.argv[2]
    topic = sys.argv[3]
    kafka_bootstrap = sys.argv[4]

    schema = load_avro_schema(avsc_file)
    produce_avro_messages(jsonl_file, schema, topic, kafka_bootstrap)
