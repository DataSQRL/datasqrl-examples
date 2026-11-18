# Logistics

- **Builds:** a real-time pipeline and data API for shipment tracking served to customers.
- **Shows:** real-time · data API
- **Built with:** SQRL compiled to Flink, Kafka, Postgres, and the DataSQRL API server.

This example replicates shipment delivery in Manhattan: real-time tracking served to customers.
Monitor and manage shipments as they move through the city and answer queries like the number of shipments per
customer and their current locations. Amazingly, all of this is achieved in just 33 lines of code,
imports included. How cool is that?

Run the example with:
```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest run logistics_test_package.json
```

## Regenerate test data

Normally, there is no need to regenerate the test data if you are using pre-configured sets.
However, if you wish to modify or experiment with the data, here's how you can generate your own test data.

- Remove the `datagen/generated` folder.
- Then navigate to the logistics root directory and run the following commands:
    - `python datagen/src/generate_test_data.py` to generate fresh test data. This command generates
      three folders under the `generated` folder:
        - `assets`: In this folder, you can find the plotted route for each event when a vehicle
          status was emitted. Alongside them, there is a `logistics.gif` which is an animation
          created from the plots. We only commit the last `png` file to show the full route; any
          other file is irrelevant, as they are needed for the gif creation. We didn't add
          automation to delete them because this way you can use them for your experiments.
        - `db`: In this folder, you can find the entities which could live in an RDBMS.
        - `stream`: In this folder, you can find the events which would be emitted by a sensor on
          the vehicle or by a scanner in the distribution center.

### Using Virtual Python Environment

See [Python Utilities](../util/README.md) for details.


## Build this with the DataSQRL plugin

Install the [DataSQRL plugin](https://github.com/DataSQRL/datasqrl-plugin) in Claude Code, Codex, Cursor, or Copilot, then paste this prompt:

```text
Build a DataSQRL pipeline for shipment tracking. Combine customers, shipments, and vehicles
from a database with a stream of vehicle location and shipment status events, and serve each
customer's shipments with their current location and status through a GraphQL API.
```
