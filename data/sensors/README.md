# Sensors Package

This is the data package for the Sensors Quickstart Tutorial.

## Sneak Peek at the Data

This package contains SensorReading data in CSV format:

| sensorid | time                      | temperature            | humidity |
| -------- | ------------------------- | ---------------------- | -------- |
| 0        | 2024-04-04 00:00:00.000Z  | 21.792012246728603     | 93.0     |
| 1        | 2024-04-04 00:00:00.000Z  | 28.1723170944317       | 42.0     |
| 2        | 2024-04-04 00:00:00.000Z  | 7.9208043131776975     | 32.0     |
| 3        | 2024-04-04 00:00:00.000Z  | 20.97774650879999      | 0.0      |
| 4        | 2024-04-04 00:00:00.000Z  | 10.531277579045298     | 71.0     |

## How to Use It

Create a new file called `metrics.sqrl` and copy-paste the following SQL code:

```sql
IMPORT datasqrl.example.sensors.SensorReading; -- Import metrics
IMPORT time.endOfSecond;  -- Import time function

/* Aggregate sensor readings to second */
SecReading := SELECT sensorid, endOfSecond(time) as timeSec,
                     avg(temperature) as temp 
              FROM SensorReading GROUP BY sensorid, timeSec;

/* Get max temperature in last minute per sensor */
SensorMaxTemp := SELECT sensorid, max(temp) as maxTemp
                 FROM SecReading
                 WHERE timeSec >= now() - INTERVAL 1 MINUTE
                 GROUP BY sensorid;
```

Ensure that Docker is installed on your system. Then, run the following command to start the Docker container:

```bash
docker run -it -p 8888:8888 -p 8081:8081 -v $PWD:/build datasqrl/cmd run metrics.sqrl
```

This command starts a Docker container and maps your current directory (`$PWD`) to the `/build` directory in the container. It also maps ports 8888 and 8081 from the container to your host machine.

#### A more detailed guide on the above example can be found [here](http://www.datasqrl.com/docs/getting-started/quickstart/).