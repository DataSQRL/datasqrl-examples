# Healthcare Study Monitoring

This examples demonstrates DataSQRLs capabilities creating a pipeline for healthcare study data. 

## Architecture

The data pipeline ingests raw data from a local fine and piles it into a postgres database which is connected to vertx graphql console. 

The entire pipeline can run locally.

## How to run the project

Navigate to the `healthcare-study-monitoring` directory and run the following command to compile the pipeline, this takes the given script and option and creates a pipeline. 

```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/sqrl-demo:latest compile study_api.sqrl
```

The generated pipeline can be found in the new `/build` directory. 

To run the pipeline use the following command. 
```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/sqrl-demo:latest run study_api.sqrl
```
If the pipeline hasn't been compiled, it will be compiled. 

Lastly, the compiled pipeline includes unit and integration tests, you can run these using the test command:
```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/sqrl-demo:latest test study_api.sqrl
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

### Study Analytics

### Study Stream Kafka

