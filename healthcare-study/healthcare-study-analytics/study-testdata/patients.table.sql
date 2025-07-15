CREATE TABLE Patients (
    `patientId` BIGINT NOT NULL,
    `studyId` BIGINT NOT NULL,
    `name` STRING NOT NULL,
    `bloodGroup` STRING,
    `dateOfBirth` STRING,
    `diagnosis` STRING,
    `lastUpdated` TIMESTAMP_LTZ(3) NOT NULL,
    PRIMARY KEY (`patientId`, `lastUpdated`) NOT ENFORCED,
    WATERMARK FOR `lastUpdated` AS `lastUpdated` - INTERVAL '0.001' SECOND
) WITH (
    'format' = 'flexible-json',
    'path' = '${DATA_PATH}/patients.jsonl',
    'source.monitor-interval' = '10 min',
    'connector' = 'filesystem'
);