CREATE TABLE Merchant (
    merchantId BIGINT NOT NULL,
    name STRING NOT NULL,
    category STRING NOT NULL,
    updatedTime TIMESTAMP_LTZ(3) NOT NULL,
    PRIMARY KEY (`merchantId`, `updatedTime`) NOT ENFORCED,
    WATERMARK FOR `updatedTime` AS `updatedTime` - INTERVAL '1' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/merchant.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );