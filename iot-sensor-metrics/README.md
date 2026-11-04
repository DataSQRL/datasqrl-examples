# Sensor API

This is an example API for recording and analyzing metrics data.
Specifically, this API collects the temperature readings of sensors.

The project keeps its configuration in a base manifest plus thin per-environment overlays, selected through `script.config.environment`:

| Environment | Readings come from | Overlay |
|-------------|--------------------|---------|
| `test` | the sample file `connectors/testdata/readings.jsonl` (`connectors/sources_test.sqrl`) | `sensors-test-package.json` |
| `dev` | the API — `SensorReading` is a DataSQRL-managed Kafka table exposed as a GraphQL **mutation** (`connectors/sources_dev.sqrl`) | `sensors-dev-package.json` |

DataSQRL merges the manifests in the order they are given (later files override earlier ones), so every command passes the base first and the overlay second.

## Run the API

To run the API with mutation-based ingestion, execute

```bash
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/workspace datasqrl/cmd:latest run \
  sensors-shared-package.json \
  sensors-dev-package.json
```

To check that the GraphQL API is running properly, [open GraphiQL](http://localhost:8888/v1/graphiql/) to access the API.

## Run the Tests

`run-tests.sh` is the single entry point for the test suites:

```bash
./run-tests.sh              # test environment: file data, snapshot tests
./run-tests.sh --env dev    # dev environment: mutations -> subscription -> query, snapshotted end to end
./run-tests.sh --list-invocations   # print what would run without running it
```

The dev suite in `sensors-api/tests/` ingests readings through the `SensorReading` mutation, collects the `HighTemp` subscription events they trigger, and queries `ReadingsAboveTemp` --> all snapshotted (`snapshots/sensors_dev/`).

## Add Temperature Readings to Running API

Once the API is up and running, you can access it through GraphiQL, a GraphQL IDE by opening
[http://localhost:8888/v1/graphiql/](http://localhost:8888/v1/graphiql/) in your browser.

You can record sensor data through the API by copy-pasting the following GraphQL mutation and running it in GraphiQL:
```graphql
mutation AddReading {
  SensorReading(event: {sensorid: 1, temperature: 44.1}) {
    sensorid
  }
}
```

Run the query a few times to add some data. Feel free to change the temperature and sensor id.

Once you are done, hit CTRL-C.
