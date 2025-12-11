CREATE TABLE EnrichedIndicator (
    PRIMARY KEY (patientId) NOT ENFORCED
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/enriched_indicator/',
      'connector' = 'filesystem',
      'flexible-json.timestamp-format.standard' = 'ISO-8601'
      ) LIKE `*`;
