CREATE TABLE EnrichedContactAvro (
  PRIMARY KEY (firstname) NOT ENFORCED
) WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'enrichedcontact_avro',
  'properties.bootstrap.servers' = 'host.docker.internal:9092',
  'key.format' = 'avro-confluent',
  'key.avro-confluent.url' = 'http://host.docker.internal:8081',
  'value.format' = 'avro-confluent',
  'value.avro-confluent.url' = 'http://host.docker.internal:8081'
);
