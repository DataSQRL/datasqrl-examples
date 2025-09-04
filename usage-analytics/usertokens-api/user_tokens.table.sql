CREATE TABLE UserTokens (
    `userid` BIGINT NOT NULL,
    `tokens` BIGINT NOT NULL,
    `request_time` TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp'
);
