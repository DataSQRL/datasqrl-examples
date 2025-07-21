CREATE TABLE Bolo (
     PRIMARY KEY (`bolo_id`, `last_updated`) NOT ENFORCED,
     WATERMARK FOR `last_updated` AS `last_updated`
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/bolo.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );