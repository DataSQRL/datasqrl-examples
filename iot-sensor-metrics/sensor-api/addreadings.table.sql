CREATE TABLE AddReadings (
   sensorid INT NOT NULL,
   temperature decimal(8,2) NOT NULL,
   event_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp'
);