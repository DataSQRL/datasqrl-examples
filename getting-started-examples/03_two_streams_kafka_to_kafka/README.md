# Kafka-to-Kafka with Avro using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- Reads data from two kafka topics and combines the data from two streams using temporal join
- writes output to another kafka topic
- Kafka is part of datasqrl package.



## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:

```bash
docker run -it --rm -p 8888:8888 -p 9092:9092 -v $PWD:/build datasqrl/cmd:0.7.1 run -c package.json
```

## Generate Data

* Go to `data-generator` folder 
  * `python3 load_data.py <jsonl_file> <kafka_broker_address> <topic_name>`
* To send Contact data
```bash
 python3 load_data.py contact.jsonl localhost:9092 contact
```
* To send Organization data
```bash
 python3 load_data.py organization.jsonl localhost:9092 organization
```


## Output

* Updated records should be generated in enrichedcontact topic. 
