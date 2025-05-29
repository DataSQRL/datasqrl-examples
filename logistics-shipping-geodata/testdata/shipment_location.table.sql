CREATE TABLE ShipmentLocation (
    `timestamp` TIMESTAMP_LTZ(3) NOT NULL,
    `shipmentId` BIGINT NOT NULL,
    `vehicleId` BIGINT NOT NULL,
    PRIMARY KEY (`timestamp`, `shipmentId`, `vehicleId`) NOT ENFORCED,
    WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '0.001' SECOND
) WITH (
    'format' = 'flexible-json',
    'path' = '${DATA_PATH}/shipment_location.jsonl',
    'connector' = 'filesystem'
);