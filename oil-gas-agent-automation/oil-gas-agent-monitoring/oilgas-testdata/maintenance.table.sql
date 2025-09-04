CREATE TABLE Maintenance (
    `work_order_id` BIGINT NOT NULL,
    `work_order_num` STRING NOT NULL,
    `asset_id` BIGINT NOT NULL,
    `description` STRING NOT NULL,
    `wo_type` STRING NOT NULL,
    `priority` STRING NOT NULL,
    `status` STRING NOT NULL,
    `request_date` STRING NOT NULL,
    `start_date` STRING,
    `completion_date` STRING,
    `lastUpdated` TIMESTAMP_LTZ(3) NOT NULL,
     PRIMARY KEY (`work_order_id`, `lastUpdated`) NOT ENFORCED,
     WATERMARK FOR `lastUpdated` AS `lastUpdated`
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/maintenance.jsonl',
      'source.monitor-interval' = '10000',
      'connector' = 'filesystem'
);
