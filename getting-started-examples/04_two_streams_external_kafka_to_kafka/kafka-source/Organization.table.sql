CREATE TABLE Organization (
  userid BIGINT,
  orgid BIGINT,
  orgname STRING,
  last_updated TIMESTAMP_LTZ(3) METADATA FROM 'timestamp',
  WATERMARK FOR last_updated AS last_updated - INTERVAL '30' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'organization',
  'properties.bootstrap.servers' = 'host.docker.internal:9092',
  'properties.group.id' = 'group1_organization',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'flexible-json'
);
