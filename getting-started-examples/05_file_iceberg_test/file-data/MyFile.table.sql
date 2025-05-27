CREATE TABLE MyFile (
    id INT,
    name STRING,
    amount DOUBLE,
    event_time TIMESTAMP_LTZ(3)
) WITH (
    'connector' = 'filesystem',
    'path' = '${DATA_PATH}/myfile.jsonl',
    'format' = 'flexible-json'
);
