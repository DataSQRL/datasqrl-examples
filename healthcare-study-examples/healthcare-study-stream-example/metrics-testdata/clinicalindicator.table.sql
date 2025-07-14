CREATE TABLE ClinicalIndicator (
     `timestamp` AS TO_TIMESTAMP_LTZ(`time`,3),
     WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/clinicalindicator.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
      );