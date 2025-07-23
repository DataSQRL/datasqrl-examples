CREATE TABLE `transactions` (
  `transaction_id` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `debit_account_id` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `credit_account_id` VARCHAR(2147483647) CHARACTER SET `UTF-16LE` NOT NULL,
  `amount` DOUBLE NOT NULL,
  `tx_time` TIMESTAMP(3) WITH LOCAL TIME ZONE NOT NULL,
  `note` VARCHAR(2147483647) CHARACTER SET `UTF-16LE`,
  WATERMARK FOR `tx_time` AS `tx_time` - INTERVAL '0.001' SECOND
) WITH (
  'connector' = 'filesystem',
  'format' = 'flexible-json',
  'path' = '${DATA_PATH}/transactions.jsonl',
  'source.monitor-interval' = '10 sec'
);