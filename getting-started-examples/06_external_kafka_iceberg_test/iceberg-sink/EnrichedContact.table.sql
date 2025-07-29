CREATE TABLE EnrichedContact (
  WATERMARK FOR last_updated AS last_updated - INTERVAL '1' SECOND
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'mycatalog',
  'catalog-type' = 'hadoop',
  'warehouse' = '/data/iceberg',
  'format-version' = '2'
);
