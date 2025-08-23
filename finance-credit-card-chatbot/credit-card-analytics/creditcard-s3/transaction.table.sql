CREATE TABLE Transaction (
    transactionId BIGINT NOT NULL,
    cardNo STRING NOT NULL,
    `time` TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
    amount DOUBLE NOT NULL,
    merchantId BIGINT NOT NULL,
    WATERMARK FOR `time` AS `time` - INTERVAL '1' SECOND
) WITH (
      'connector' = 'filesystem',
      'format' = 'flexible-json',
      'path' = 's3://example-data.dev.datasqrl.com/mvp/transaction.jsonl',
      'source.monitor-interval' = '1 min'
      );