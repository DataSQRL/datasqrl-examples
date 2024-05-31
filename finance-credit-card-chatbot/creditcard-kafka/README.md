# Kafka Source Data

To use Kafka as the source for the transactions and merchant rewards, you need to:

1. Create the additional topics `transaction` and `merchantReward` in Kafka.
2. Once the topics have been successfully created, load the data using the `load_data.py` script.