CREATE TABLE Content (
     url STRING NOT NULL,
     title STRING NOT NULL,
     text STRING NOT NULL,
     update_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
     WATERMARK FOR update_time AS update_time - INTERVAL '0.001' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'content',
    'properties.bootstrap.servers' = '${KAFKA_BOOTSTRAP_SERVERS}',
    'properties.group.id' = 'clickstream-group',
    'scan.startup.mode' = 'group-offsets',
    'properties.auto.offset.reset' = 'earliest',
    'format' = 'flexible-json'
    );
