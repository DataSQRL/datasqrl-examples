CREATE TABLE ClinicalIndicator (
   sensorId BIGINT NOT NULL,
   metric DOUBLE NOT NULL,
   `timestamp` TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp'
);