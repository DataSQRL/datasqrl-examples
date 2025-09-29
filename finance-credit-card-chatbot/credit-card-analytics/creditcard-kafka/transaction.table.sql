CREATE TABLE Transaction (
    transactionId BIGINT NOT NULL,
    cardNo STRING NOT NULL,
    `time` TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
    amount DOUBLE NOT NULL,
    merchantId BIGINT NOT NULL,
    WATERMARK FOR `time` AS `time` - INTERVAL '1' SECOND
) WITH (
      'connector' = 'kafka',
      'properties.bootstrap.servers' = '${KAFKA_BOOTSTRAP_SERVERS}',
      'properties.group.id' = 'mygroupid',
      'scan.startup.mode' = 'group-offsets',
      'properties.auto.offset.reset' = 'earliest',
      'value.format' = 'flexible-json',
      'topic' = 'transaction'
      );
