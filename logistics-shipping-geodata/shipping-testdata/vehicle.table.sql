CREATE TABLE Vehicle (
    `id` BIGINT NOT NULL,
    `lastUpdated` TIMESTAMP_LTZ(3) NOT NULL,
    `type` STRING NOT NULL,
    `capacity` BIGINT NOT NULL,
     PRIMARY KEY (`id`) NOT ENFORCED,
     WATERMARK FOR `lastUpdated` AS `lastUpdated` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/vehicle.jsonl',
      'connector' = 'filesystem'
      );