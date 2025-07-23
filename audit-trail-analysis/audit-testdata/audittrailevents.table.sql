CREATE TABLE AuditTrailEvents (
   record_id STRING NOT NULL,
   user_id BIGINT NOT NULL,
   update_type STRING NOT NULL,
   event_time TIMESTAMP_LTZ(3) NOT NULL,
   WATERMARK FOR `event_time` AS `event_time` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/audittrailevents.jsonl',
      'connector' = 'filesystem'
      );