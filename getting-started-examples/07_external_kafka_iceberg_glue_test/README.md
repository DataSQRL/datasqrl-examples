# Kafka-to-Kafka with Avro using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- This example demonstrates how to use kafka and glue 
- We read from kafka topic and write data to s3 in iceberg glue format

> [!IMPORTANT]
> To run this program you would need access to AWS S3
> You should have a credentials file in your ~/.aws directory

## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:
```bash
docker run -it --rm \
  -p 8888:8888 \
  -p 8081:8081 \
  -v $PWD:/build \
  -v ~/.aws:/root/.aws \
  -e AWS_REGION=us-east-1 \
  -e S3_WAREHOUSE_PATH=s3://<bucket>/path/to/warehouse/ \
  datasqrl/cmd:latest run -c package.json
```
> [!NOTE]
> We removed `-p 9092:9092` as we are using our own Kafka running locally on host machine now
> You also need to set `s3://<bucket>/path/to/warehouse/`

## Generate Data

* Go to `data-generator` folder
  * `python3 load_data.py <jsonl_file> <kafka_broker_address> <topic_name>`
* To send Contact data
```bash
python3 load_data.py contacts.jsonl contact
```

## Output

* Updated records should be generated in `enrichedcontact` table.
