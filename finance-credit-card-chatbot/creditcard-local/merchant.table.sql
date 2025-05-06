CREATE TABLE Merchant (
     PRIMARY KEY (`merchantId`, `updatedTime`) NOT ENFORCED,
     WATERMARK FOR `updatedTime` AS `updatedTime` - INTERVAL '1' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/merchant.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );