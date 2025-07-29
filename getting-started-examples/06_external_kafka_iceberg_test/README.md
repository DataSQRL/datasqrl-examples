# Kafka-to-Kafka with Avro using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- This example uses Kafka that is running outside DataSQRL docker on host machine
- Reads data from kafka topic and writes to an iceberg table locally

## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:
```bash
docker run -it --rm -p 8888:8888 -p 8081:8081 -v $PWD:/build -v $PWD/data:/data datasqrl/cmd:0.7.0 run -c package.json
```
> [!NOTE]
> We removed `-p 9092:9092` as we are using our own kafka running locally on host machine now

## Generate Data

* Go to `data-generator` folder
   * `python3 load_data.py <jsonl_file> <kafka_broker_address> <topic_name>`
* To send Contact data
```bash
python3 load_data.py contacts.jsonl contact
```

## Output

* Updated records should be generated in `enrichedcontact` topic.
