# Iceberg Data Deduplication

- **Builds:** lake maintenance for operational pipelines: batch jobs that compact and deduplicate an Iceberg table that a CDC pipeline keeps appending to.
- **Shows:** Iceberg · batch
- **Built with:** SQRL compiled to Flink in batch mode, with Java user-defined functions that read Iceberg partition metadata and delete compacted files.

Operational pipelines that capture changes (CDC) from a database append every change to the lake. The table then holds many versions of each row, spread across many small files, and every reader has to deduplicate them. This example runs as scheduled batch jobs next to such a pipeline and keeps the table clean: one current version per key, in fewer, larger files.

## How it works

The `DedupData` table is partitioned by a key column (`account_id`) and a `time_bucket` column. New data lands in buckets greater than 0; bucket 0 holds the compacted, deduplicated data. Three jobs work on it:

| Job | Script | What it does |
| --- | --- | --- |
| Generate data | [`datagen.sqrl`](datagen.sqrl) | Writes sample CDC records from [`tables/min_source_records.jsonl`](tables/min_source_records.jsonl) into `DedupData`, each in a time bucket. |
| Compact | [`data_compaction.sqrl`](data_compaction.sqrl) | Reads the partition sizes, scores each partition by how much new data it holds, picks the partitions to compact within a size budget, keeps the latest version of each key (`distinctKeyCol`, ordered by `timestampCol`), and overwrites bucket 0 with the result. It records each compaction in the `CompactionTracker` table. |
| Delete | [`data_delete.sqrl`](data_delete.sqrl) | Reads `CompactionTracker` and, once a compaction has committed, deletes the now-duplicated data in the compacted partitions' newer buckets. It records the outcome in `CompactionTracker`. |

The user-defined functions in [`udfs`](udfs) (`read_partition_sizes`, `delete_duplicated_data`) talk to the Iceberg catalog directly. The prebuilt JAR is checked in; rebuild it with `mvn package` in that folder.

Everything that is specific to a table is a script parameter in the package files: the catalog and table, the key, partition, time bucket and timestamp columns, an optional delete-flag column, the bucket size, and the compaction size budget. Point the parameters at your own table to reuse the jobs.

| Package files | Catalog |
| --- | --- |
| `*_package_local.json` | Hadoop catalog in the local `sqrl-iceberg-data` directory |
| `*_package_test.json` | AWS Glue catalog with an S3 warehouse; needs AWS credentials |

## Run locally

Run the three jobs in order from this directory:

```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest run datagen_package_local.json
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest run data_compaction_package_local.json
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest run data_delete_package_local.json
```

The Iceberg data is written to `sqrl-iceberg-data`. Run `datagen` and `data_compaction` again to see that partitions which were already compacted are skipped until they get new data.

To compile a job without running it, replace `run` with `compile`.

To run against AWS Glue and S3, use the `*_package_test.json` files and pass your AWS credentials with `-e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_REGION`.

## Build this with the DataSQRL plugin

Install the [DataSQRL plugin](https://github.com/DataSQRL/datasqrl-plugin) in Claude Code, Codex, Cursor, or Copilot, then paste this prompt:

```text
Build a DataSQRL batch job that compacts an Iceberg table written by a CDC pipeline. The table
is partitioned by account_id and a time bucket. Keep only the latest version of each id by
timestamp, rewrite the compacted partitions, and track every compaction in a separate Iceberg
table so a second job can delete the duplicated data once the compaction has committed.
```
