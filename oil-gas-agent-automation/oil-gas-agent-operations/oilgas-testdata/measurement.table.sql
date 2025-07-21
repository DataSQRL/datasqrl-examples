CREATE TABLE Measurement (
    `assetId` BIGINT NOT NULL,
    `pressure_psi` DOUBLE NOT NULL,
    `temperature_f` DOUBLE NOT NULL,
    `timestamp` TIMESTAMP_LTZ(3) NOT NULL,
     PRIMARY KEY (`assetId`, `timestamp`) NOT ENFORCED,
     WATERMARK FOR `timestamp` AS `timestamp`
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/measurement.jsonl.gz',
      'source.monitor-interval' = '10000',
      'connector' = 'filesystem'
      );