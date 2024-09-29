import argparse
from kafka import KafkaConsumer

def consume_messages(broker_ip, topic_name):
    consumer = KafkaConsumer(
        topic_name,
        bootstrap_servers=[broker_ip],
        auto_offset_reset='latest',
        enable_auto_commit=True,
        group_id='my-group')

    print(f"Connected to Kafka broker at {broker_ip}, listening to topic '{topic_name}'")
    try:
        for message in consumer:
            print(f"Received message: {message.value.decode('utf-8')}")
    except KeyboardInterrupt:
        print("Stopped consuming messages.")
    finally:
        consumer.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Kafka Topic Consumer")
    parser.add_argument("broker_ip", help="IP and port of the Kafka broker (e.g., localhost:9092)")
    parser.add_argument("topic_name", help="Name of the Kafka topic to consume from")

    args = parser.parse_args()
    consume_messages(args.broker_ip, args.topic_name)
