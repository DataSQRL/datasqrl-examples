# Kafka-to-Kafka with Avro using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- This example uses kafka that is running outside of docker on host machine
- Reads data from two kafka topics and combines the data from two streams using temporal join
- Writes output to another kafka topic running on host machine
- We are not using kafka running inside DataSQRL

## Few things to note

* `'properties.bootstrap.servers' = 'host.docker.internal:9092'` -> this tells docker to connect to your host machine's kafka 
* You don't need to create output topic `enrichedcontact`
* `create-topics` array from `package.json` was removed since we are using external Kafka, where we expect source topics to be present 
* We removed kafka engine from `enabled-engines` array in `package.json`

## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:
```bash
docker run -it --rm -p 8888:8888 -p 8081:8081 -v $PWD:/build -v $PWD/data:/data datasqrl/cmd:0.7.1 run -c package.json
```
> [!NOTE]
> We removed `-p 9092:9092` as we are using our own kafka running locally on host machine now

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

* Updated records should be generated in `enrichedcontact` table.
