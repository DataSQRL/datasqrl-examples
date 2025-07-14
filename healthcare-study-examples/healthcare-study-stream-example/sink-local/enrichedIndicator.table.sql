CREATE TABLE EnrichedIndicator (
    PRIMARY KEY (patientId) NOT ENFORCED
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/sink/enrichedIndicator/',
      'connector' = 'filesystem',
      'flexible-json.timestamp-format.standard' = 'ISO-8601'
      );