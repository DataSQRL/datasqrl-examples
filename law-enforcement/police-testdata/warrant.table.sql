CREATE TABLE Warrant (
     PRIMARY KEY (`warrant_id`, `last_updated`) NOT ENFORCED,
     WATERMARK FOR `last_updated` AS `last_updated` - INTERVAL '0' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/warrant.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
) LIKE `warrant.schema.yml`;
