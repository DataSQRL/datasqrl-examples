# Kafka-to-Kafka with Avro using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- This example reads data from a file and writes it to an iceberg table locally

## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:

```bash
docker run -it --rm -p 8888:8888 -p 8081:8081 -v $PWD:/build datasqrl/cmd:latest run -c package.json
```

> [!NOTE]
> Iceberg files will be stored in the `warehouse` directory set by `package.json`

## Output

* There should be iceberg files and folders generated in `$PWD/warehouse` directory 
* Data for the output table will reside in `ProcessedData` (as defined in the sqrl script)
