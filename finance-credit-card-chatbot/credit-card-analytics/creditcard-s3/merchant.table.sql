CREATE TABLE Merchant (
    merchantId BIGINT NOT NULL,
    name STRING NOT NULL,
    category STRING NOT NULL,
    updatedTime TIMESTAMP_LTZ(3) NOT NULL  METADATA FROM 'timestamp',
    WATERMARK FOR `updatedTime` AS `updatedTime` - INTERVAL '1' SECOND
) WITH (
    'connector' = 'filesystem',
    'format' = 'flexible-json',
    'path' = 's3://${S3_DATA_BUCKET}/merchant.jsonl',
    'source.monitor-interval' = '1 min'
    );