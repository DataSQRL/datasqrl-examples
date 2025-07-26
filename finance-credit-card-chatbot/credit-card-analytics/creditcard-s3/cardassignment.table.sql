CREATE TABLE CardAssignment (
    customerId BIGINT NOT NULL,
    cardNo STRING NOT NULL,
    cardType STRING NOT NULL,
    `timestamp` TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
    WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '1' SECOND
) WITH (
      'connector' = 'filesystem',
      'format' = 'flexible-json',
      'path' = 's3://${S3_DATA_BUCKET}/cardAssignment.jsonl',
      'source.monitor-interval' = '1 min'
      );
