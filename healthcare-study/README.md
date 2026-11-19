# Healthcare Study Monitoring Examples

- **Builds:** one shared catalog feeding three systems: a data API over patients and their metrics, analytics tables in Iceberg, and an enriched stream published to Kafka.
- **Shows:** Kafka · data API · Iceberg
- **Built with:** SQRL compiled to Flink, Kafka, Postgres, the DataSQRL API server, and Iceberg, read by DuckDB or Snowflake.

This is the example of a pipeline that lands data in the lake and serves an API from the same sources. The analytics tables in Iceberg are for a warehouse or query engine to read; models inside the warehouse stay in dbt.

These examples demonstrate DataSQRL's capabilities creating pipelines for healthcare study data.

We are ingesting metadata, patient data, sensor placements, and observation group assignments from
master data systems, and clinical indicator readings (metrics) from sensors.

All three use cases share the [`data-catalog`](data-catalog), which provides every dataset per environment:
in `test` the master data and the sensor readings come from the sample files (`study_test.sqrl`,
`metrics_test.sqrl`); in `dev` they come from Kafka — one topic per master dataset (`study_dev.sqrl`) and the
readings topic `indicators` (`metrics_dev.sqrl`, schema from `schema/clinical_indicator.avsc`). The analytics
use case reads the sample files in both of its environments.
The stream use case owns its sink (`study_stream_sinks_<env>.sqrl`): a local directory in `test`, the Kafka
topic `enrichedindicators` in `dev`. Every source and sink is a `CREATE TABLE … LIKE` definition, taking its
schema from a data file, an Avro schema, or — for the sink — the exported table itself (`LIKE \`*\``).

The `dev` overlays list their Kafka topics under `test-runner.create-topics`: that is what makes a local
`run` or `test` start its own Redpanda and create the topics, so the `${KAFKA_BOOTSTRAP_SERVERS}` the
connectors reference resolves without any setup. To use an external broker instead, export
`KAFKA_BOOTSTRAP_SERVERS` yourself (the `prod` overlays expect that).

Each use case keeps its configuration in a **base manifest** plus thin per-environment overlays —
`<script>-shared-package.json`, `<script>-test-package.json` and `<script>-dev-package.json` or
`<script>-prod-package.json` — selecting the environment through `script.config.environment`. DataSQRL
merges the manifests in the order they are given (later files override earlier ones), so every command
passes the base first and the overlay second. The catalog sits next to the projects, so the commands
mount this directory at `/workspace` and name the project with `-r`:

```bash
cd healthcare-study
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest run \
  -r healthcare-study-api \
  study_api-shared-package.json \
  study_api-test-package.json
```

Every use case also ships a `run-tests.sh` at its root, the single entry point for its test suites:
`./run-tests.sh` runs every suite, `./run-tests.sh --compile --env dev` (or `prod`) compiles another
environment, and `./run-tests.sh --list-invocations` prints what would run without running it.

Proceed to the specific examples:
* [Healthcare Study API Example](healthcare-study-api): serves patients and their hourly metrics through
  a GraphQL API and pushes out-of-range readings as a subscription (environments: `test`, `dev`).
* [Healthcare Study Analytics Example](healthcare-study-analytics): aggregates readings per observation
  group into Iceberg tables queried by DuckDB, or Snowflake in production (environments: `test`, `prod` — both
  read the sample files; they differ in where the data lands and what queries it).
* [Healthcare Study Stream Example](healthcare-study-stream): enriches every reading and writes it to the
  `enrichedindicators` topic (environments: `test`, `dev`).


## Build this with the DataSQRL plugin

Install the [DataSQRL plugin](https://github.com/DataSQRL/datasqrl-plugin) in Claude Code, Codex, Cursor, or Copilot, then paste this prompt:

```text
Build a DataSQRL pipeline for a clinical study. Read study metadata, patients, sensor
placements, and observation groups from Kafka, plus clinical indicator readings from a Kafka
topic. Serve patients and their hourly metrics through a GraphQL API with a subscription for
out-of-range readings, and write per-group aggregates to Iceberg tables for Snowflake to query.
```
