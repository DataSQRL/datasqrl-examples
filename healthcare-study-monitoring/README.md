# Healthcare Study Monitoring

This examples demonstrates DataSQRLs capabilities creating a pipeline for healthcare study data. 

## Architecture

The data pipeline ingests raw data from a local fine and piles it into a postgres database which is connected to vertx graphql console. 

The entire pipeline can run locally.

## How to run the project

Navigate to the `healthcare-study-monitoring` directory and run the following command to compile the pipeline, this takes the given script and option and creates a pipeline. 

```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest compile study_api.sqrl
```

The generated pipeline can be found in the new `/build` directory. 

To run the pipeline use the following command. 
```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest run study_api.sqrl
```
If the pipeline hasn't been compiled, it will be compiled. 

Lastly, the compiled pipeline includes unit and integration tests, you can run these using the test command:
```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest test study_api.sqrl
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

## The examples

### Study API
This script creates a simple graphql api for the masterdata-local and metrics-kafka data.

### Join Examples
This script demonstrates the different types of join offered by flink. 

### Study Analytics
This script creates a pipeline that included aggregation. 

This script uses a package configuration, to compile/run/test such a script, you need to replace the command (compile/run/test) with `-c package_name.json`. 

Running the study_analytics script would look like this:
```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest run -c study_analytics_package.json  
```

### Study Stream Kafka
This script shows how to ingest data from a kafka stream. 

To run this example you need to expose the kafka port, this is done in the run command by adding the port with `-p xyz:123`. 

For this example the command will look like this:
```
docker run -it -p 8081:8081 -p 9092:9092 --rm -v $PWD:/build datasqrl/cmd:latest -c study_stream_kafka_package.json
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