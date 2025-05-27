CREATE TABLE Contact (
  id BIGINT,
  firstname STRING,
  lastname STRING,
  last_updated TIMESTAMP_LTZ(3) METADATA FROM 'timestamp',
  WATERMARK FOR last_updated AS last_updated - INTERVAL '1' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'contact',
  'properties.bootstrap.servers' = 'host.docker.internal:9092',
  'properties.group.id' = 'group1_contacts',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'flexible-json'
);
