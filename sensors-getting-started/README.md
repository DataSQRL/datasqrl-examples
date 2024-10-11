# Data Package for the Sensors Example

This data package is used by the Sensors (Getting Started) example which demonstrates DataSQRL's capabilities by
building a sensor metrics data pipeline. It serves as an ideal use case for real-time data aggregation, showcasing how
sensor readings can be processed to monitor environmental changes such as temperature and humidity. In this example,
we will compute the maximum temperature from sensors in just a few SQL queries.
All of this is achieved in less than 15 lines of code, including imports!

## Data Overview

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

For further details on how this package works check out our detailed
[Sensor Data Tutorial](http://www.datasqrl.com/docs/getting-started/quickstart/) tutorial.
