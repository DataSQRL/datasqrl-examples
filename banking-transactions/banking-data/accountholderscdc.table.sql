CREATE TABLE `accountholderscdc` (
  `holder_id` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `name` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `type` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `update_time` TIMESTAMP(3) WITH LOCAL TIME ZONE NOT NULL,
  WATERMARK FOR `update_time` AS `update_time`
) WITH (
  'connector' = 'filesystem',
  'format' = 'flexible-json',
  'path' = '${DATA_PATH}/accountholderscdc.jsonl',
  'source.monitor-interval' = '10 sec'
);