CREATE TABLE Vehicle (
     PRIMARY KEY (`id`) NOT ENFORCED,
     WATERMARK FOR `lastUpdated` AS `lastUpdated` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/vehicle.jsonl',
      'connector' = 'filesystem'
      );