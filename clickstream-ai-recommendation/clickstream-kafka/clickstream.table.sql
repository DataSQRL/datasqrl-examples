CREATE TABLE AddClick (
    url STRING NOT NULL,
    userid STRING NOT NULL,
    event_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
    WATERMARK FOR event_time AS event_time - INTERVAL '0.001' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'clickstream',
    'properties.bootstrap.servers' = '${PROPERTIES_BOOTSTRAP_SERVERS}',
    'properties.group.id' = 'clickstream-group',
    'scan.startup.mode' = 'group-offsets',
    'properties.auto.offset.reset' = 'earliest',
    'format' = 'flexible-json'
      );