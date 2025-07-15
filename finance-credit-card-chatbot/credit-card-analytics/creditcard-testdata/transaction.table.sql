CREATE TABLE Transaction (
    transactionId BIGINT NOT NULL,
    cardNo STRING NOT NULL,
    `time` TIMESTAMP_LTZ(3) NOT NULL,
    amount DOUBLE NOT NULL,
    merchantId BIGINT NOT NULL,
    PRIMARY KEY (`transactionId`, `time`) NOT ENFORCED,
    WATERMARK FOR `time` AS `time` - INTERVAL '1' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/transaction.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );