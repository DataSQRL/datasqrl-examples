CREATE TABLE Contact (
  id BIGINT,
  firstname STRING,
  lastname STRING,
  last_updated TIMESTAMP_LTZ(3) METADATA FROM 'timestamp',
  WATERMARK FOR last_updated AS last_updated - INTERVAL '1' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'contacts',
  'properties.bootstrap.servers' = '${KAFKA_BOOTSTRAP_SERVERS}',
  'properties.group.id' = '${KAFKA_GROUP_ID}',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'flexible-json'
);
