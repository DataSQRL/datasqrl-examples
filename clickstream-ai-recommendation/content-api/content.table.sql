CREATE TABLE Content (
    url STRING NOT NULL,
    title STRING NOT NULL,
    text STRING NOT NULL,
    update_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp'
)