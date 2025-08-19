import json
import sys
from kafka import KafkaProducer

def load_data(file_path, topic):
    producer = KafkaProducer(
        bootstrap_servers='localhost:9092',
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )
    with open(file_path, 'r') as f:
        for line in f:
            record = json.loads(line)
            producer.send(topic, record)
    producer.flush()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python load_data.py <jsonl_file> <topic>")
        sys.exit(1)
    load_data(sys.argv[1], sys.argv[2])
