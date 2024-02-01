# Clickstream Recommendation

This SQRL script creates personalized content recommendations based on clickstream data and content vector embeddings.

## How to Run

There are three ways to run this example depending on how you want to consume the data.

### From Local Files

This is the easiest way to run the example as it will read the data from local files without any additional steps.

To read from local files, use the following imports for the data (and only those two imports):

```sql
IMPORT yourdatafile.Clickstream TIMESTAMP _ingest_time;
IMPORT yourdatafile.Content TIMESTAMP _ingest_time;
```

Then execute the following steps:
1. Run the following command in the root directory to compile: `docker run -it -p 8888:8888 -p 8081:8081 -v $PWD:/build datasqrl/cmd compile recommendation.sqrl recommendation.graphqls --mnt $PWD`
2. Then run cd into the `build/deploy` directory
3. Start with `docker compose up`
4. Once you are done, take down with `docker compose down -v`

Open GraphiQL to see if you can query the data:
`http://localhost:8888/graphiql/`

### From Local Files and API

This reads the content data from local files and ingests the clickstream data through the API.

Use the following import statements:
```sql
IMPORT recommendation.Clickstream TIMESTAMP _source_time;
IMPORT yourdatafile.Content TIMESTAMP _ingest_time;
```

Follow the steps above. You won't see any data until you have added data through executing the mutation in GraphiQL.

### Ingest from Stream

**This has not yet been tested**

This read the data from the stream directly and requires that you add the data to the stream specifically.

Use the following import statements:
```sql
IMPORT yourdata.Clickstream;
IMPORT yourdata.Content;
```

Follow steps 1 and 2 above. Before launching the microservice, make sure you create the topics for the data streams. Do this by adding the following lines to the `create-topics.sh` file.

```
/opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --topic clickstream --partitions 1 --replication-factor 1
/opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --topic content --partitions 1 --replication-factor 1
```

Then stand up the microservice with step 3.
Once everything is started up, add data to Kafka using the `load_data.py` script in the `yourdata-files` directory.

1. Load the content data: `python3 load_data.py content.json.gz localhost:9092 content`. Wait until it finishes.
2. Load the clickstream data:   `python3 load_data.py click_part0001.json.gz localhost:9092 clickstream 100`. This loads 100 clicks per second. Wait a few seconds. Then you should be able to query data in GraphiQL.
