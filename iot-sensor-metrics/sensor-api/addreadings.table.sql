CREATE TABLE AddReadings (
   sensorid INT NOT NULL,
   temperature decimal(8,2) NOT NULL,
   event_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
   WATERMARK FOR `event_time` AS `event_time` - INTERVAL '0.001' SECOND
);