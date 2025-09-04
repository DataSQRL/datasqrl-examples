CREATE TABLE ContactUpdated (
    WATERMARK FOR last_updated AS last_updated - INTERVAL '1' SECOND
) WITH (
      'connector' = 'kafka',
      'properties.bootstrap.servers' = '${KAFKA_BOOTSTRAP_SERVERS}',
      'properties.group.id' = 'mygroupid',
      'scan.startup.mode' = 'group-offsets',
      'properties.auto.offset.reset' = 'earliest',
      'value.format' = 'flexible-json',
      'topic' = 'contactupdated'
) LIKE `*`;
