# Test Jobs

This folder contains simple DataSQRL test jobs to evaluate operations without external dependencies.

Unlike the other projects in this repository, these jobs are not real use cases but meant solely for
testing.

* [Aggregation](aggregation-test.sqrl): Tests Flink with logging using generated data
* [Aggregation Query](aggregation-query-test.sqrl): Tests Flink -> Postgres or Iceberg -> Vertx using generated data
* [Aggregation Query Subscription](aggregation-query-subscription-test.sqrl): Tests Flink -> Postgres + Kafka -> Vertx using generated data
* [Mutation Iceberg](mutation-iceberg-test.sqrl): Tests GraphQL mutation -> Kafka -> Flink -> Iceberg on S3 -> DuckDB -> Vertx. Unlike the jobs above it has no `datagen` source, so **nothing happens until you post data**, and it computes three tables in the iceberg engine rather than one

## Mutation Iceberg job

`mutation-iceberg-test-package.json` writes Iceberg to `s3a://sqrl-examples-data-bucket/datasqrl-examples/iceberg-mutation-test`
using the **hadoop** catalog. No AWS Glue is involved, so the job needs nothing beyond S3 access to
that bucket and runs unchanged from any data group.

Run it with credentials that can reach the bucket:

```bash
docker run -it --rm -p 8888:8888 -p 8081:8081 \
  -e AWS_ACCESS_KEY_ID="<key>" \
  -e AWS_SECRET_ACCESS_KEY="<secret>" \
  -e AWS_REGION="us-east-1" \
  -v $PWD:/build \
  datasqrl/cmd:latest run mutation-iceberg-test-package.json
```

Post data — the watermark comes from the Kafka record timestamp, so windows only close while rows
keep arriving. A single mutation will land in `Measurement` but never closes a window:

```bash
curl -s http://localhost:8888/v1/graphql -H 'Content-Type: application/json' -d '{
  "query": "mutation($e:[InputDataInput!]!){ InputData(event:$e){ uniqueId event_time } }",
  "variables": {"e": [{"uniqueId":"a1","measure":600.0,"partitionId":"a"}]}
}'
```

Then read it back through DuckDB. Allow ~20-40s: a row is only queryable once Flink checkpoints and
commits to Iceberg.

```bash
curl -s http://localhost:8888/v1/graphql -H 'Content-Type: application/json' \
  -d '{"query":"{ Measurement(limit:5){ uniqueId partitionId measure event_time } }"}'
curl -s http://localhost:8888/v1/graphql -H 'Content-Type: application/json' \
  -d '{"query":"{ Aggregation(limit:5){ partitionId window_start window_end total_measure record_count } }"}'
```

> [!IMPORTANT]
> The warehouse path is fixed, so the Iceberg tables persist between runs. If you change a column
> in the SQRL script, compilation fails with `Field <name> not found in source schema` — Iceberg is
> reconciling against the table already at that path. Clear it first:
> `aws s3 rm s3://sqrl-examples-data-bucket/datasqrl-examples/iceberg-mutation-test/ --recursive`

> [!NOTE]
> Running locally, DuckDB reads S3 with the `AWS_*` environment variables above. Deployed to a
> cluster where the pod authenticates through IRSA, the **write** side works but DuckDB queries
> return `HTTP 403`: its `httpfs` extension never exchanges the projected web-identity token. That
> needs the credential-chain support in DataSQRL/sqrl#2098.