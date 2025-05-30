CREATE TABLE EnrichedContact (
  WATERMARK FOR last_updated AS last_updated - INTERVAL '1' SECOND
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'mycatalog',
  'catalog-type' = 'hadoop',
  'warehouse' = '${S3_WAREHOUSE_PATH}',
  'format-version' = '2'
  'aws.region' = 'us-east-1'
);
