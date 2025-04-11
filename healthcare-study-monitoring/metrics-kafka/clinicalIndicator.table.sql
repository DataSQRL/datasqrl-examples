CREATE TABLE Indicators (
     `timestamp` TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
     WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '0.001' SECOND
) WITH (
      'connector' = 'kafka',
      'topic' = 'indicators',
      'properties.bootstrap.servers' = '${PROPERTIES_BOOTSTRAP_SERVERS}',
      'properties.group.id' = 'mygroup',
      'scan.startup.mode' = 'earliest-offset',
      'format' = 'flexible-json'
      );