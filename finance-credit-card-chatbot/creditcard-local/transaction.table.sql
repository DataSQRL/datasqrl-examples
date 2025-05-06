CREATE TABLE Transaction (
     PRIMARY KEY (`transactionId`, `time`) NOT ENFORCED,
     WATERMARK FOR `time` AS `time` - INTERVAL '1' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/transaction.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );