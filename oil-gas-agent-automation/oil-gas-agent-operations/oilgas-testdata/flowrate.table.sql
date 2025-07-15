CREATE TABLE Flowrate (
    `assetId` BIGINT NOT NULL,
    `flowrate` DOUBLE NOT NULL,
    `event_time` TIMESTAMP_LTZ(3) NOT NULL,
     PRIMARY KEY (`assetId`, `event_time`) NOT ENFORCED,
     WATERMARK FOR `event_time` AS `event_time`
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/flowrate.jsonl.gz',
      'source.monitor-interval' = '10000',
      'connector' = 'filesystem'
      );