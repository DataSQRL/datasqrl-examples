# Kafka-to-Kafka with Avro using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- This example demonstrates how to use kafka and glue 
- We read from kafka topic and write data to s3 in iceberg glue format

## Note:
- To run this program you would need access to aws s3 
- you should have a credentials file in your ~/.aws directory


## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:

Note: 
- We removed `-p 9092:9092` as we are using our own kafka running locally on host machine now
- you also need to set `s3://[BUCKET]/path/to/folder/`
```bash
docker run -it --rm \
  -p 8888:8888 \
  -p 8081:8081 \
  -v $PWD:/build \
  -v ~/.aws:/root/.aws \
  -e AWS_REGION=us-east-1 \
  -e S3_WAREHOUSE_PATH=s3://[BUCKET]/path/to/folder/ \
  datasqrl/cmd:dev run -c package.json

```

## Generate Data

* Go to `data-generator` folder
   * `python3 load_data.py <jsonl_file> <kafka_broker_address> <topic_name>`
* To send Contact data
```bash
python3 load_data.py contacts.jsonl contact
```



## Output

* Updated records should be generated in enrichedcontact topic.


