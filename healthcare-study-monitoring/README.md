# Healthcare Study Monitoring

This examples demonstrates DataSQRLs capabilities creating a pipeline for healthcare study data. 

We are ingesting metadata, patient data, sensor placement, and observation group assignments from master data systems.

We are ingesting metrics data from kafka.

This example produces multiple types of data products from that source data:

## Study Data API

Run the study API with:

```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest run -c study_api_package_api.json
```

This example demonstrates how to use the package.json configuration files to map import packages to different folders for testing vs production:

```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest test -c study_api_package_test.json
```

While the pipeline runs can check if the data has been ingested in the flink console. 

```
http://localhost:8081/
```

You can also open the GraphQL console:
```
http://localhost:8888/graphiql/
```

In this console you can check out the imported data using graphQL queries like this. 
```
query {
    ClinicalIndicator {
        sensorId
        time
        metric
        timestamp
    }
}
```

## Study Analytics
This script produces study analytics for observations groups in iceberg tables that are queried by DuckDB.

Run the study_analytics script using iceberg and duckdb locally as follows:
```
docker run -it -p 8888:8888 -p 8081:8081 --rm -v $PWD:/build datasqrl/cmd:latest run -c study_analytics_package_test.json
```

This writes the data to the local directory `warehouse` which is configured in `study_analytics_package_test.json` under the `warehouse` configuration option. Delete that directory if you re-run the example or make changes to it, otherwise you might run into errors of catalog mismatch.

There is also a package configuration for running this example using Snowflake as the query engine. 

## Study Stream Kafka
This script shows how to ingest data from a kafka stream. 

For this example the command will look like this:
```
docker run -it -p 8081:8081 -p 9092:9092 --rm -v $PWD:/build datasqrl/cmd:latest run -c study_stream_package_kafka.json
```

You'll need the kafka-python. We recommend using a new venv:

Note: There is a breaking bug in the kafka-python library, please see the [issue](https://github.com/dpkp/kafka-python/issues/2412).
```
python3 -m venv py-venv
source py-venv/bin/activate
python -m pip install --break-system-packages git+https://github.com/dpkp/kafka-python.git
```

To load the data, go to the /util folder:
```
source py-venv/bin/activate
python3 ../util/load_data.py ../data/clinicalindicator.jsonl localhost:9092 indicators
```

To observe the data, run:
```
source py-venv/bin/activate
python3 ../util/read_data.py localhost:9092 enrichedindicators
```