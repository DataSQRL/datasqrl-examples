CREATE TABLE Assets (
     PRIMARY KEY (`asset_id`, `lastUpdated`) NOT ENFORCED,
     WATERMARK FOR `lastUpdated` AS `lastUpdated`
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/assets.jsonl',
      'source.monitor-interval' = '10000',
      'connector' = 'filesystem'
      );