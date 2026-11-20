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
    'connector' = 'filesystem',
    'format' = 'flexible-json',
    'path' = 's3://example-data.dev.datasqrl.com/mvp/merchantReward.jsonl',
    'source.monitor-interval' = '1 min'
    );