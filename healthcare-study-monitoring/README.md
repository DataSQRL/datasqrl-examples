# Healthcare Study Monitoring

This examples demonstrates DataSQRLs capabilities creating a pipeline for healthcare study data. 

## Architecture

The data pipeline ingests raw data from a local fine and piles it into a postgres database which is connected to vertx graphql console. 

The entire pipeline can run locally.

## How to run the project

Simple navigate to the `healthcare-study-monitoring` directory and run the following command. 

```
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/sqrl-demo:latest run study_api.sqrl
```

This will trigger the pipeline described in the `study_api.sqrl` file to be compiled and activated. 

Upon running you can check if the data has been ingested in the flink console. 

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
