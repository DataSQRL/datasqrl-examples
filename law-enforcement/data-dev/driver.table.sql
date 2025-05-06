CREATE TABLE Driver (
     PRIMARY KEY (`driver_id`, `last_updated`) NOT ENFORCED,
     WATERMARK FOR `last_updated` AS `last_updated` - INTERVAL '0' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/driver.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );