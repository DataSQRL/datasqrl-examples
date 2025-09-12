CREATE TABLE Readings (
   sensorid INT NOT NULL,
   temperature decimal(8,2) NOT NULL,
   event_time TIMESTAMP_LTZ(3) NOT NULL,
   WATERMARK FOR `event_time` AS `event_time` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/readings.jsonl',
      'connector' = 'filesystem'
);
