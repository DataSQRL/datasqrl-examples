CREATE TABLE Assets (
    `asset_id` BIGINT NOT NULL,
    `asset_number` STRING NOT NULL,
    `asset_name` STRING NOT NULL,
    `asset_category_id` BIGINT NOT NULL,
    `description` STRING NOT NULL,
    `date_placed_in_service` STRING NOT NULL,
    `asset_cost` BIGINT NOT NULL,
    `status` STRING NOT NULL,
    `asset_manual` STRING NOT NULL,
    `lastUpdated` TIMESTAMP_LTZ(3) NOT NULL,
     PRIMARY KEY (`asset_id`, `lastUpdated`) NOT ENFORCED,
     WATERMARK FOR `lastUpdated` AS `lastUpdated`
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/assets.jsonl',
      'source.monitor-interval' = '10000',
      'connector' = 'filesystem'
);
