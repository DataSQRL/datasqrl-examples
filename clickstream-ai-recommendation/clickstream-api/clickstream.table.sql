CREATE TABLE Clickstream (
    url STRING NOT NULL,
    userid STRING NOT NULL,
    event_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp'
);
