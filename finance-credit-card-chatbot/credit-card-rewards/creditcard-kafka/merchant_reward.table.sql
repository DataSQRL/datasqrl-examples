CREATE TABLE MerchantReward (
    merchantId BIGINT NOT NULL,
    rewardsByCard ARRAY<ROW<
            cardType STRING,
            rewardPercentage BIGINT,
            startTimestamp BIGINT,
            expirationTimestamp BIGINT
        >> NOT NULL,
    updatedTime TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
    WATERMARK FOR `updatedTime` AS `updatedTime` - INTERVAL '1' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = '${KAFKA_BOOTSTRAP_SERVERS}',
    'properties.group.id' = 'mygroupid',
    'scan.startup.mode' = 'group-offsets',
    'properties.auto.offset.reset' = 'earliest',
    'value.format' = 'flexible-json',
    'topic' = 'merchantreward'
    );
