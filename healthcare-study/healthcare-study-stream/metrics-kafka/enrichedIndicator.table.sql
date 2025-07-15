CREATE TABLE EnrichedIndicators (
     WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '5' SECOND
) WITH (
      'connector' = 'kafka',
      'topic' = 'enrichedindicators',
      'properties.bootstrap.servers' = '${PROPERTIES_BOOTSTRAP_SERVERS}',
      'properties.group.id' = 'mygroup',
      'scan.startup.mode' = 'earliest-offset',
      'value.format' = 'flexible-json',
      'key.format' = 'raw',
      'key.fields' = 'patientId'
);