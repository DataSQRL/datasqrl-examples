CREATE TABLE Contact (
  last_updated TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
  WATERMARK FOR last_updated AS last_updated - INTERVAL '1' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'contact',
  'properties.bootstrap.servers' = '${KAFKA_BOOTSTRAP_SERVERS}',
  'properties.group.id' = 'user-consumer-group',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'avro'
) LIKE `contact.avsc`;
