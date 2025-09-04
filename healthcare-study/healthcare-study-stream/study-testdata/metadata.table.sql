CREATE TABLE Metadata (
    `metadataId` BIGINT NOT NULL,
    `name` STRING NOT NULL,
    `lowRange` DOUBLE NOT NULL,
    `highRange` DOUBLE NOT NULL,
    `lastUpdated` TIMESTAMP_LTZ(3) NOT NULL,
     PRIMARY KEY (`metadataId`, `lastUpdated`) NOT ENFORCED,
     WATERMARK FOR `lastUpdated` AS `lastUpdated` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/metadata.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
);
