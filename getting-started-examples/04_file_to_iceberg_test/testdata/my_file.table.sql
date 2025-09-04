CREATE TABLE MyFile (
    id INT,
    name STRING,
    amount DOUBLE,
    event_time TIMESTAMP_LTZ(3)
) WITH (
    'connector' = 'filesystem',
    'path' = '${DATA_PATH}/my_file.jsonl',
    'format' = 'flexible-json'
);
