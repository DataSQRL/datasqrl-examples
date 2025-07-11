CREATE TABLE `organization` (
  `userid` BIGINT NOT NULL,
  `orgid` BIGINT NOT NULL,
  `orgname` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `last_updated` TIMESTAMP(3) WITH LOCAL TIME ZONE NOT NULL,
  `event_time` AS NOW(),
  WATERMARK FOR `event_time` AS `event_time` - INTERVAL '0.001' SECOND
) WITH (
  'connector' = 'filesystem',
  'format' = 'flexible-json',
  'path' = '${DATA_PATH}/organization.jsonl',
  'source.monitor-interval' = '10 sec'
);