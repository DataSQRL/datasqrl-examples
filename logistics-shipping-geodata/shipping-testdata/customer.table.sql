CREATE TABLE Customer (
    `id` BIGINT NOT NULL,
    `lastUpdated` TIMESTAMP_LTZ(3) NOT NULL,
    `email` STRING NOT NULL,
    `phone` STRING NOT NULL,
     PRIMARY KEY (`id`) NOT ENFORCED,
     WATERMARK FOR `lastUpdated` AS `lastUpdated` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/customer.jsonl',
      'connector' = 'filesystem'
);
