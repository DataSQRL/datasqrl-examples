# Sensor API

This is an example API for recording and analyzing metrics data.
Specifically, this API collects the temperature readings of sensors.

## Run the API

To run the API, execute

```bash
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest run -c sensor_package_api.json
```

To check that the GraphQL API is running properly, [open GraphiQL](http://localhost:8888/graphiql/) to access the API.

## Run the Tests

```bash
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest test -c sensor_package_test.json
```

## Add Temperature Readings to Running API

Once the API is up and running, you can access it through GraphiQL, a GraphQL IDE by opening
[http://localhost:8888//graphiql/](http://localhost:8888//graphiql/) in your browser.

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