CREATE TABLE Contact (
  firstname STRING not null,
  lastname STRING,
  last_updated TIMESTAMP_LTZ(3) METADATA FROM 'timestamp',
  WATERMARK FOR last_updated AS last_updated - INTERVAL '1' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'contact',
  'properties.bootstrap.servers' = 'host.docker.internal:9092',
  'properties.group.id' = 'group1_contacts',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'avro-confluent',
  'avro-confluent.url' = 'http://host.docker.internal:8081'
);
