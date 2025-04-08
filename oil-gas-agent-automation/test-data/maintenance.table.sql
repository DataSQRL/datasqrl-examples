CREATE TABLE Maintenance (
     PRIMARY KEY (`work_order_id`, `lastUpdated`) NOT ENFORCED,
     WATERMARK FOR `lastUpdated` AS `lastUpdated`
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/maintenance.jsonl',
      'source.monitor-interval' = '10000',
      'connector' = 'filesystem'
      );