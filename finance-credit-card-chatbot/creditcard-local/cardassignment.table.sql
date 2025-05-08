CREATE TABLE CardAssignment (
    customerId BIGINT NOT NULL,
    cardNo STRING NOT NULL,
    cardType STRING NOT NULL,
    `timestamp` TIMESTAMP_LTZ(3) NOT NULL,
    PRIMARY KEY (`customerId`, `cardNo`, `timestamp`) NOT ENFORCED,
    WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '1' SECOND
) WITH (
    'format' = 'flexible-json',
    'path' = '${DATA_PATH}/cardAssignment.jsonl',
    'source.monitor-interval' = '10 min',
    'connector' = 'filesystem'
);