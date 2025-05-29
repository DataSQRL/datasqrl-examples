CREATE TABLE VehicleStatus (
    `timestamp` TIMESTAMP_LTZ(3) NOT NULL,
    `lat` DOUBLE NOT NULL,
    `lon` DOUBLE NOT NULL,
    `vehicleId` BIGINT NOT NULL,
     PRIMARY KEY (`timestamp`, `vehicleId`) NOT ENFORCED,
     WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/vehicle_status.jsonl',
      'connector' = 'filesystem'
);