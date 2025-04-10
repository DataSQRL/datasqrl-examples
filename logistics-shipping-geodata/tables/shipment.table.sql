CREATE TABLE Shipment (
     PRIMARY KEY (`id`) NOT ENFORCED,
     WATERMARK FOR `lastUpdated` AS `lastUpdated` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/shipment.jsonl',
      'connector' = 'filesystem'
      );