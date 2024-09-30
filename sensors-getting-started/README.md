# Sensors Package

This example demonstrates DataSQRL’s capabilities by building a sensor metrics data pipeline. It serves as an ideal use
case for real-time data aggregation, showcasing how sensor readings can be processed to monitor environmental changes
such as temperature and humidity. In this example, we will compute the maximum temperature from sensors in just a few
SQL queries. All of this is achieved in less than 15 lines of code, including imports!

## How to run this example

We are going to build a data pipeline that aggregates sensor metrics using DataSQRL.
With DataSQRL, you can implement the entire data pipeline in a single SQL script.

1. Create a new folder for the data pipeline:
```bash
mkdir metrics; cd metrics
```

2. Create a new file called metrics.sqrl and copy-paste the following SQL code:
```sql
IMPORT datasqrl.examples.sensors.SensorReading; -- Import sensor readings
IMPORT time.endOfSecond;  -- Import time function

/* Aggregate sensor readings per second */
SecReading := SELECT sensorid, endOfSecond(time) as timeSec,
                     avg(temperature) as temp
              FROM SensorReading
              GROUP BY sensorid, timeSec;

/* Get max temperature in the last minute for each sensor */
SensorMaxTemp := SELECT sensorid, max(temp) as maxTemp
                 FROM SecReading
                 WHERE timeSec >= now() - INTERVAL 1 MINUTE
                 GROUP BY sensorid;
```

3. Compile the SQL script to an integrated data pipeline:
```bash
docker run -it --rm -v $PWD:/build datasqrl/cmd:v0.5.5 compile metrics.sqrl
```

4. By default, DataSQRL uses Docker to run data pipelines locally. Start the pipeline with Docker Compose:
```bash
(cd build/deploy; docker compose up --build)
```

5. Once you are done, hit CTRL-C and take down the pipeline containers with:
```bash
docker compose down -v 
```

## Exploring the Pipeline

Once the pipeline is up and running, you can explore it by querying the data through a GraphQL API.

#### How to check the maximum temperature for a sensor?

Navigate to http://localhost:8888/graphiql/ and execute GraphQL queries to interact with the pipeline.

##### Query Example: Maximum Temperature for a Sensor

The following GraphQL query retrieves the maximum temperature recorded in the last minute for sensor id: 1:

```graphql
{
  SensorMaxTemp(sensorid: 1) {
    maxTemp
  }
}
```

##### Expected Response

```json
{
  "data": {
    "SensorMaxTemp": [
      {
        "maxTemp": 28.17
      }
    ]
  }
}
```

##### Query Example: Sensor Readings Aggregated by Time

To fetch the average temperature for sensor readings aggregated by second:
```graphql
{
  SecReading(limit: 5) {
    sensorid,
    timeSec,
    temp
  }
}
```

##### Expected Response

The response will provide a list of sensor readings aggregated by time:
```graphql
{
    "data": {
        "SecReading": [
            {
                "sensorid": 1,
                "timeSec": "2024-04-04T00:00:00Z",
                "temp": 28.1723170944317
            },
            {
                "sensorid": 2,
                "timeSec": "2024-04-04T00:00:00Z",
                "temp": 7.9208043131776975
            }
        ]
    }
}
```

## Understanding the Input Data

The data used in this example represents sensor readings and is provided in CSV format.
Each record contains a sensorid, a timestamp (time), and corresponding temperature and humidity readings.
Here is a sample of the input data:

| sensorid | time                      | temperature            | humidity |
| -------- | ------------------------- | ---------------------- | -------- |
| 0        | 2024-04-04 00:00:00.000Z  | 21.792012246728603     | 93.0     |
| 1        | 2024-04-04 00:00:00.000Z  | 28.1723170944317       | 42.0     |
| 2        | 2024-04-04 00:00:00.000Z  | 7.9208043131776975     | 32.0     |
| 3        | 2024-04-04 00:00:00.000Z  | 20.97774650879999      | 0.0      |
| 4        | 2024-04-04 00:00:00.000Z  | 10.531277579045298     | 71.0     |

## Additional Resources

For further details on how DataSQRL works and additional tutorials,
check out the official [Sensor Data Tutorial](http://www.datasqrl.com/docs/getting-started/quickstart/).
