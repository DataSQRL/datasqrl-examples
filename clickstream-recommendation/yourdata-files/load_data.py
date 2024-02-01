import argparse
import time
import gzip
from kafka import KafkaProducer

def publish_messages(file_name, broker_ip, topic_name, messages_per_second):
    producer = KafkaProducer(bootstrap_servers=broker_ip)

    with gzip.open(file_name, 'rt') as f:
        start_time = time.time()
        message_count = 0

        for line in f:
            if message_count >= messages_per_second:
                elapsed_time = time.time() - start_time
                if elapsed_time < 1:
                    time.sleep(1 - elapsed_time)
                start_time = time.time()
                message_count = 0
                producer.flush()

            producer.send(topic_name, line)
            message_count += 1

    producer.flush()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("file_name", help="Name of the input file")
    parser.add_argument("broker_ip", help="IP and port of the broker")
    parser.add_argument("topic_name", help="Name of the topic")
    parser.add_argument("--msg", help="Number of messages per second", type=int, default=1000)

    args = parser.parse_args()
    publish_messages(args.file_name, args.broker_ip, args.topic_name, args.messages_per_second)