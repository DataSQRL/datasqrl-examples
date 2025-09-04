CREATE TABLE ClinicalIndicator (
     `timestamp` AS TO_TIMESTAMP_LTZ(`time`,3),
     WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/clinical_indicator.jsonl',
      'source.monitor-interval' = '10 min',
      'connector' = 'filesystem'
) LIKE `clinical_indicator.avsc`;
