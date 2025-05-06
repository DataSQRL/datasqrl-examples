CREATE TABLE ObservationGroup (
     PRIMARY KEY (`groupId`, `createdDate`) NOT ENFORCED,
     WATERMARK FOR `createdDate` AS `createdDate` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/observationgroup.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );