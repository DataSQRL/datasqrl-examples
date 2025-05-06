CREATE TABLE Measurement (
     PRIMARY KEY (`assetId`, `timestamp`) NOT ENFORCED,
     WATERMARK FOR `timestamp` AS `timestamp`
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/measurement.jsonl.gz',
      'source.monitor-interval' = '10000',
      'connector' = 'filesystem'
      );