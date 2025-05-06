CREATE TABLE Transaction (
     WATERMARK FOR `time` AS `time` - INTERVAL '1' SECOND
) WITH (
      'connector' = 'kafka',
      'properties.bootstrap.servers' = '${PROPERTIES_BOOTSTRAP_SERVERS}',
      'properties.group.id' = 'mygroupid',
      'scan.startup.mode' = 'group-offsets',
      'properties.auto.offset.reset' = 'earliest',
      'value.format' = 'flexible-json',
      'topic' = 'transaction'
      );