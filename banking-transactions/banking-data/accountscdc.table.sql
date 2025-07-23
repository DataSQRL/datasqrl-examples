CREATE TABLE `accountscdc` (
  `account_id` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `holder_id` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `account_type` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `balance` DOUBLE NOT NULL,
  `status` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `update_time` TIMESTAMP(3) WITH LOCAL TIME ZONE NOT NULL,
  WATERMARK FOR `update_time` AS `update_time`
) WITH (
  'connector' = 'filesystem',
  'format' = 'flexible-json',
  'path' = '${DATA_PATH}/accountscdc.jsonl',
  'source.monitor-interval' = '10 sec'
);