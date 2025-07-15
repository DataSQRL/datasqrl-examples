CREATE TABLE SensorPlacements (
    `sensorId` BIGINT NOT NULL,
    `patientId` BIGINT NOT NULL,
    `metadataId` BIGINT NOT NULL,
    `eventId` STRING NOT NULL,
    `placedTimestamp` TIMESTAMP_LTZ(3) NOT NULL,
     PRIMARY KEY (`eventId`) NOT ENFORCED,
     WATERMARK FOR `placedTimestamp` AS `placedTimestamp` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/sensorplacements.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );
