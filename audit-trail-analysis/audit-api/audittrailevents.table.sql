CREATE TABLE AuditTrailEvents (
   record_id STRING NOT NULL,
   user_id BIGINT NOT NULL,
   update_type STRING NOT NULL,
   event_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp'
);