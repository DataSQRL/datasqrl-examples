CREATE TABLE MerchantReward (
    merchantId BIGINT NOT NULL,
    rewardsByCard ARRAY<ROW<cardType STRING, rewardPercentage BIGINT, startTimestamp BIGINT, expirationTimestamp BIGINT>> NOT NULL,
    updatedTime TIMESTAMP_LTZ(3) NOT NULL,
    PRIMARY KEY (`merchantId`, `updatedTime`) NOT ENFORCED,
    WATERMARK FOR `updatedTime` AS `updatedTime` - INTERVAL '1' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/merchantReward.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );
