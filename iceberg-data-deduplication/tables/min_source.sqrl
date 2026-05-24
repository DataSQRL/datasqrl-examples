CREATE TABLE SrcRecords (
    WATERMARK FOR ts AS ts - INTERVAL '0.001' SECOND
) WITH (
    'connector' = 'filesystem'
) LIKE `min_source_records.jsonl`;
