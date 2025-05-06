CREATE TABLE VehicleStatus (
     PRIMARY KEY (`timestamp`, `vehicleId`) NOT ENFORCED,
     WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/vehicle_status.jsonl',
      'connector' = 'filesystem'
);