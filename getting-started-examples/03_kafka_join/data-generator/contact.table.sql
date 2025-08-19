CREATE TABLE `contact` (
  `id` BIGINT NOT NULL,
  `firstname` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `lastname` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `event_time` AS NOW(),
  WATERMARK FOR `event_time` AS `event_time` - INTERVAL '0.001' SECOND
) WITH (
  'connector' = 'filesystem',
  'format' = 'flexible-json',
  'path' = '${DATA_PATH}/contact.jsonl',
  'source.monitor-interval' = '10 sec'
);