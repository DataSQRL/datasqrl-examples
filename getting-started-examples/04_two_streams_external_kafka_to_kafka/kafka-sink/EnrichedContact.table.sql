CREATE TABLE EnrichedContact (
  WATERMARK FOR last_updated AS last_updated - INTERVAL '30' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'enrichedcontact',
  'properties.bootstrap.servers' = 'host.docker.internal:9092',
  'format' = 'flexible-json'
);
