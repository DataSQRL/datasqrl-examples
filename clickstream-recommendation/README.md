# Clickstream Recommendation

This SQRL script creates personalized content recommendations based on clickstream data and content vector embeddings.

## How to Run

There are two ways to run this example depending on how you want to ingest the clickstream data.

***IMPORTANT NOTE:*** If you want to run these examples with the most recent development version, use `datasqrl/cmd:dev` as the docker image in the commands below.

### From Local Files and API

This reads the content data from local files and ingests the clickstream data through the API.

Use the following import statements in the `recommendation.sqrl` file:
```sql
IMPORT recommendationMutation.Clickstream TIMESTAMP _source_time;
IMPORT yourdatafile.Content TIMESTAMP _ingest_time AS timestamp;
```

Then execute the following steps:
1. Run the following command in the root directory to compile: `docker run -it -p 8888:8888 -p 8081:8081 -v $PWD:/build datasqrl/cmd compile recommendation.sqrl recommendationMutation.graphqls -p redpanda.profile.docker --mnt $PWD`
2. Then run cd into the `build/deploy` directory
3. Start with `docker compose up`
4. 

Open GraphiQL to add and query data.

First, add some clickstream data for the user with id `f5e9c688-408d-b54f-94aa-493df43dac8c` by running the following three mutation one after the other.
```graphql
mutation {
  Clickstream(click: {userid: "f5e9c688-408d-b54f-94aa-493df43dac8c",
  url: "https://en.wikipedia.org/wiki/Generosity%3A%20An%20Enhancement"}) {
    _source_time
  }
}
```

```graphql
mutation {
  Clickstream(click: {userid: "f5e9c688-408d-b54f-94aa-493df43dac8c",
  url: "https://en.wikipedia.org/wiki/Lock%27s%20Quest"}) {
    _source_time
  }
}
```

```graphql
mutation {
  Clickstream(click: {userid: "f5e9c688-408d-b54f-94aa-493df43dac8c",
  url: "https://en.wikipedia.org/wiki/SystemC"}) {
    _source_time
  }
}
```

Now, query for recommendations. Either by page:
```graphql
query {
  Recommendation(url: "https://en.wikipedia.org/wiki/Generosity%3A%20An%20Enhancement") {
    recommendation
    frequency
  }
}
```
or for our user:
```graphql
query {
  SimilarContent(userid: "f5e9c688-408d-b54f-94aa-493df43dac8c") {
    url
    similarity
  }
}
```

Once you are done, take down the pipeline with `docker compose down -v`.

As an alternative to `docker compose`, you can also run this pipeline with DataSQRL's `run` command:

```bash
docker run -it -p 8888:8888 -p 8081:8081 -v $PWD:/build datasqrl/cmd:dev run recommendation.sqrl recommendationMutation.graphqls
```

Once this has started up, run the same queries above in GraphiQL. To take down the pipeline, hit `CTRL-C`.

### Ingest from Stream

This read the data from the stream directly and requires that you add the data to the stream specifically.

Use the following import statements:
```sql
IMPORT yourdata.Clickstream;
IMPORT yourdata.Content TIMESTAMP _source_time AS timestamp;
```

Then execute the following steps:
1. Run the following command in the root directory to compile: `docker run -it -p 8888:8888 -p 8081:8081 -v $PWD:/build datasqrl/cmd compile recommendation.sqrl recommendation.graphqls -p redpanda.profile.docker --mnt $PWD`
2. Then run cd into the `build/deploy` directory
3. Create the topics for the data by adding the following lines to the `create-topics.sh` file before `exit 0;`:
```
/opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --topic clickstream --partitions 1 --replication-factor 1
/opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --topic content --partitions 1 --replication-factor 1
```
4. Start with `docker compose up`
5. Once everything is started up, open another terminal window to add data to Kafka using the `load_data.py` script in the `yourdata-files` directory. This requires you have `kafka-python` installed via `pip3 install kafka-python`.
7. Load the content data: `python3 load_data.py content.json.gz localhost:9094 content --msg 50`. Wait until it finishes (we need all the content in there before we can click on it.)
8. Load the clickstream data:   `python3 load_data.py clickstream.json.gz localhost:9094 clickstream --msg 100`. This loads 100 clicks per second. Wait a few seconds for some data to load. However, you don't have to wait for all of it to load. After a second or two, data should be processed and queryable. Let this run in the background until it finishes (which takes about 4 minutes).

Open GraphiQL and query the data:
`http://localhost:8888/graphiql/`

Query for recommendations either by page:
```graphql
query {
  Recommendation(url: "https://en.wikipedia.org/wiki/Generosity%3A%20An%20Enhancement") {
    recommendation
    frequency
  }
}
```
or for a user:
```graphql
query {
  SimilarContent(userid: "f5e9c688-408d-b54f-94aa-493df43dac8c") {
    url
    similarity
  }
}
```

You can find all the page URLs in the file `datawiki/wikipedia_urls.txt` and user ids in the file `yourdata-files/clickstream.json.gz` (read it with `gzcat`) if you want to experiment with different queries.

Once you are done, hit `CTRL-C` and take down the pipeline containers with `docker compose down -v`.