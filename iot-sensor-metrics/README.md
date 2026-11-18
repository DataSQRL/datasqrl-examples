# Sensor API

- **Builds:** a data API that ingests sensor readings, processes them in real-time, and serves metrics and alerts.
- **Shows:** data API · real-time
- **Built with:** SQRL compiled to Flink, Kafka, Postgres, and the DataSQRL API server.

This is an example API for recording and analyzing metrics data.
Specifically, this API collects the temperature readings of sensors.

## Run the API

To run the API, execute

```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest run sensors_package_api.json
```

To check that the GraphQL API is running properly, [open GraphiQL](http://localhost:8888/v1/graphiql/) to access the API.

## Run the Tests

```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest test sensors_package_test.json
```

## Add Temperature Readings to Running API

Once the API is up and running, you can access it through GraphiQL, a GraphQL IDE by opening
[http://localhost:8888/v1//graphiql/](http://localhost:8888/v1//graphiql/) in your browser.

Before you run the associated ChatBot, we need to record some sensor data through the API.
You can do that by copy-pasting the following GraphQL mutation query and running it in GraphiQL:
```graphql
mutation AddReading {
  SensorReading(metric: {sensorid: 1, temperature: 44.1}) {
    _source_time
  }
}
```

Run the query a few times to add some data. Feel free to change the temperature and sensor id.

Once you are done, hit CTRL-C.


## Build this with the DataSQRL plugin

Install the [DataSQRL plugin](https://github.com/DataSQRL/datasqrl-plugin) in Claude Code, Codex, Cursor, or Copilot, then paste this prompt:

```text
Build a DataSQRL data API for temperature sensors. Add a GraphQL mutation to record readings,
compute per-minute averages and maximums per sensor, serve them through a query, and push an
alert through a subscription when a sensor's temperature goes above a threshold.
```
