CREATE TABLE Patients (
    PRIMARY KEY (`patientId`, `lastUpdated`) NOT ENFORCED,
    WATERMARK FOR `lastUpdated` AS `lastUpdated` - INTERVAL '0.001' SECOND
) WITH (
    'format' = 'flexible-json',
    'path' = '${DATA_PATH}/patients.jsonl',
    'source.monitor-interval' = '10 min',
    'connector' = 'filesystem'
);