# Kafka-to-Kafka with Avro using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- Reads data from a kafka topic and prints output to console
- Kafka is part of the DataSQRL package.

## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:

```bash
docker run -it --rm -p 8888:8888 -p 9092:9092 -v $PWD:/build datasqrl/cmd:latest run -c package.json
```

## Generate Data

* Go to `data-generator` folder 
```bash
python3 send_kafka_avro_records.py ../kafka-source/contact.avsc data.jsonl contact localhost:9092
```
