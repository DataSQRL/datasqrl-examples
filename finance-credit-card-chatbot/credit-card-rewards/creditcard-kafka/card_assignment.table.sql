CREATE TABLE CardAssignment (
    customerId BIGINT NOT NULL,
    cardNo STRING NOT NULL,
    cardType STRING NOT NULL,
    `timestamp` TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
    WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '1' SECOND
) WITH (
      'connector' = 'kafka',
      'properties.bootstrap.servers' = '${KAFKA_BOOTSTRAP_SERVERS}',
      'properties.group.id' = 'mygroupid',
      'scan.startup.mode' = 'group-offsets',
      'properties.auto.offset.reset' = 'earliest',
      'value.format' = 'flexible-json',
      'topic' = 'cardassignment'
      );
