CREATE TABLE ObservationGroup (
    `groupId` BIGINT NOT NULL,
    `studyId` BIGINT NOT NULL,
    `groupName` STRING NOT NULL,
    `createdDate` TIMESTAMP_LTZ(3) NOT NULL,
    `patients` ARRAY<ROW<`patientId` BIGINT NOT NULL>> NOT NULL,
     PRIMARY KEY (`groupId`, `createdDate`) NOT ENFORCED,
     WATERMARK FOR `createdDate` AS `createdDate` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/observationgroup.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );