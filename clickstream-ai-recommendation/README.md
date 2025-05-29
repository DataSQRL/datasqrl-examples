# Clickstream Recommendation

We are building personalized content recommendations
based on clickstream data and content vector embeddings. The pipeline ingests data, processes it,
and serves recommendations in real time.

## Architecture

The data pipeline ingests content and clickstream data into Redpanda, processes the data with Flink
to compute recommendations, stores the recommendations in Postgres, and serves them on request
through the GraphQL API.

![Architecture of DataSQRL Pipeline for Clickstream Recommendation](img/architecture_diagram.png)

You can run this entire data pipeline locally as explained below. You can also deploy the individual
components in AWS as shown in the diagram above.

## How to Compile and Run the Project

There are two ways to run this example depending on how you want to ingest the clickstream data.

## Ingest Data from API

This version allows you to add content and clickstream data manually through a GraphQL API giving you more control over how the data is ingested and what is happening.

Run the API version with this command:
```bash
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build -e OPENAI_API_KEY=[YOUR_API_KEY_HERE] datasqrl/cmd:latest run -c recommendation_package_api.json
```

Next, open [GraphQL Explorer](http://localhost:8888/graphiql/) and add some content:
```graphql
mutation {
  Content(event: {url: "https://en.wikipedia.org/wiki/Zoop", title: "Zoop", text: "Zoop is a puzzle video game originally developed by Hookstone Productions and published by Viacom New Media for many platforms in 1995. It has similarities to Taito's 1989 arcade game Plotting (known as Flipull in other territories and on other systems) but Zoop runs in real-time instead. Players are tasked with eliminating pieces that spawn from one of the sides of the screen, before they reach the center of the playfield, by pointing at a specific piece and shooting it to either swap it with t"}) {
    title
  }
}
```
You can find more content samples to add in the [sample_content.jsonl](content-api/sample_content.jsonl) file.

Once you have added multiple pieces of content, we can register clicks with this mutation:
```graphql
mutation {
  Clickstream(event:{url:"https://en.wikipedia.org/wiki/Zoop", userid: "1"}) {
    userid
  }
}
```

Run this mutation a few times with different urls for the same userid (to create Covisits) and different userids.

To retrieve similar content to what a user has viewed before, run this query:
```graphql
{
  SimilarContent(userid: "1") {
    similarity
    title
  }
}
```

To retrieve recommendations by URL:
```graphql
{
Recommendation(url: "https://en.wikipedia.org/wiki/Zoop") {
  recommendation
  frequency
}
}
```


### Ingest from Stream

This method reads data from the stream directly and requires that you add the data to the stream specifically.

The `content-kafka` package specifies reading
data through a Kafka connector.

To run the pipeline:
```bash
docker run -it -p 8081:8081 -p 8888:8888 -p 9092:9092 --rm -v $PWD:/build -e OPENAI_API_KEY=[YOUR_API_KEY_HERE] datasqrl/cmd:latest run -c recommendation_package_kafka.json
```

1. Once everything is started, open another terminal window to add data to Kafka using the
   load_data.py script in the `yourdata-files` directory. This requires **kafka-python-ng** installed
   via `pip3 install kafka-python-ng`.
1. Load the content data: `python3 load_data.py content.json.gz localhost:9092 content --msg 50`.
   Wait until it finishes, which takes about two minutes. Check the Flink Dashboard running
   at http://localhost:8081/ to see the progress. Wait until the task turns blue again.
1. Load the clickstream
   data: `python3 load_data.py clickstream.json.gz localhost:9092 clickstream --msg 100`. This loads
   100 clicks per second. Wait a few seconds for some data to load. Let this run in the background
   until it finishes (about 4 minutes).

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

You can find all the page URLs in the file `datawiki/wikipedia_urls.txt` and user ids in the
file `yourdata-files/clickstream.json.gz` (read it with `gzcat`) if you want to experiment with
different queries.

Once you are done, hit `CTRL-C` and take down the pipeline.