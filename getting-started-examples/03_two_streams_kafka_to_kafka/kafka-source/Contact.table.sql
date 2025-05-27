CREATE TABLE Contact (
  id BIGINT,
  firstname STRING,
  lastname STRING,
  last_updated TIMESTAMP_LTZ(3) METADATA FROM 'timestamp',
  WATERMARK FOR last_updated AS last_updated - INTERVAL '30' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'contact',
  'properties.bootstrap.servers' = '${PROPERTIES_BOOTSTRAP_SERVERS}',
  'properties.group.id' = 'group1',
  'properties.auto.offset.reset' = 'earliest',
  'format' = 'flexible-json'
);
