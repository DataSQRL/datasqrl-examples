CREATE TABLE EnrichedIndicator (
    PRIMARY KEY (patientId) NOT ENFORCED
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/enrichedIndicator/',
      'connector' = 'filesystem',
      'flexible-json.timestamp-format.standard' = 'ISO-8601'
      );
