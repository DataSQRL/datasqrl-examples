CREATE TABLE `usertokens` (
  `userid` BIGINT NOT NULL,
  `tokens` BIGINT NOT NULL,
  `request_time` TIMESTAMP(3) WITH LOCAL TIME ZONE NOT NULL,
  WATERMARK FOR `request_time` AS `request_time` - INTERVAL '0.001' SECOND
) WITH (
  'connector' = 'filesystem',
  'format' = 'flexible-json',
  'path' = '${DATA_PATH}/usertokens.jsonl',
  'source.monitor-interval' = '10 sec'
);