# Logistics

This example demonstrates DataSQRL's capabilities by replicating shipment delivery in Manhattan. It
serves as an ideal use-case for streaming, showcasing real-time shipment tracking. Monitor and
manage shipments as they move through the city and answer queries like the number of shipments per
customer and their current locations. Amazingly, all of this is achieved in just 33 lines of code,
imports included. How cool is that?

Run the example with:
```bash
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest run -c logistics_package_test.json
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

