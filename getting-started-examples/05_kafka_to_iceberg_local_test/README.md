# Kafka to Local Iceberg Warehouse Using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- Reads data from a Kafka topic
- Writes data to an Iceberg table locally

## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:
```bash
docker run -it --rm -p 8888:8888 -p 8081:8081 -p 9092:9092 -v $PWD:/build datasqrl/cmd:latest run -c package.json
```

## Generate Data

* Go to `data-generator` folder
   * `python3 load_data.py <jsonl_file> <topic_name>`
* To send Contact data
```bash
python3 load_data.py contacts.jsonl contacts
```

## Output

* There should be iceberg files and folders generated in `$PWD/warehouse` directory
* Data for the output table will reside in `MyContacts` (as defined in the sqrl script)
