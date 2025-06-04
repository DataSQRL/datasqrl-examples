# SQRL Language Specification

SQRL is an extension of ANSI SQL —specifically FlinkSQL — that adds language features for **reactive data processing and serving**: table / function / relationship definitions, built-in source & sink management, and an opinionated DAG planner.  
The “R” in **SQRL** stands for *Reactive* and *Relationships*.

Readers are expected to know basic SQL and the [FlinkSQL syntax](https://nightlies.apache.org/flink/flink-docs-release-1.19/docs/dev/table/sql/overview/).  
This document focuses only on features **unique to SQRL**; when SQRL accepts FlinkSQL verbatim we simply refer to the upstream spec.

## Script Structure

A SQRL script is an **ordered list** of statements separated by semicolons (`;`).  
Only one statement is allowed per line, but a statement may span multiple lines.

Typical order of statements:

```text
IMPORT …        -- import sources from external definitions
CREATE TABLE …  -- define internal & external sources
other statements (definitions, hints, inserts, exports…)
EXPORT …        -- explicit sinks
```

At compile time the statements form a *directed-acyclic graph* (DAG).  
Each node is then assigned to an execution engine according to the optimizer and the compiler generates the data processing code for that engine.

## FlinkSQL

SQRL inherits full FlinkSQL grammar for

* `CREATE {TABLE | VIEW | FUNCTION | CATALOG | DATABASE}`
* `SELECT` queries inside any of the above
* `USE …`

…with the caveat that SQRL currently tracks **Flink 1.19**; later features may not parse.

Refer to the [FlinkSQL documentation](https://nightlies.apache.org/flink/flink-docs-release-1.19/docs/dev/table/sql/overview/) for a detailed specification.

## Type System
In SQRL, every table and function has a type based on how the table represents data. The type determines the semantic validity of queries against tables and how data is processed by different engines.

SQRL assigns one of the following types to tables based on the definition:
- **STREAM**: Represents a stream of immutable records with an assigned timestamp (often referred to as the "event time"). Streams are append-only. Stream tables represent events or actions over time.
- **VERSIONED_STATE**: Contains records with a natural primary key and a timestamp, tracking changes over time to each record, thereby creating a change-stream.
- **STATE**: Similar to VERSIONED_STATE but without tracking the history of changes. Each record is uniquely identified by its natural primary key.
- **LOOKUP**: Supports lookup operations using a primary key but does not allow further processing of the data.
- **STATIC**: Consists of data that does not change over time, such as constants.

## IMPORT Statement

```
IMPORT qualifiedPath (AS identifier)?;
IMPORT qualifiedPath.*;             -- wildcard
IMPORT qualifiedPath.* AS _;        -- hidden wildcard
```

* **Resolution:** the dotted path maps to a relative directory; the final element is the filename stem (e.g. `IMPORT datasqrl.Customer` ⇒ `datasqrl/Customer.table.sql`).
* **Aliases:** rename the imported object (`AS MyTable`).
* **Hidden imports:** prefix the alias with `_` *or* alias a wildcard to `_` to import objects without exposing them in the interface.

Examples:

```sql
IMPORT ecommerceTs.Customer;                 -- visible
IMPORT ecommerceTs.Customer AS _Hidden;      -- hidden
IMPORT ecommerceTs.* AS _;                   -- hide entire package
```

Wild-card imports with aliases *prefix* the alias to all imported table names.


## CREATE TABLE (internal vs external)

SQRL understands the complete FlinkSQL `CREATE TABLE` syntax, but distinguishes between **internal** and **external** source tables. External source tables are standard FlinkSQL tables that connect to an internal data source. Internal tables connect to a data source that is managed by SQRL (depending on the configured `log` engine, e.g. a Kafka topic) and exposed for inserts in the interface.

| Feature | Internal source (managed by SQRL) | External Source (connector) |
|---------|-----------------------------------|-----------------------------|
| Connector clause `WITH (…)` | **omitted** | **required**                |
| Computed columns | Evaluated **on insert** | Delegated to connector      |
| Metadata columns | `METADATA FROM 'uuid'`, `'timestamp'` are recognised by planner | Passed through              |
| Watermark spec | Optional | Passed through              |
| Primary key | *Unenforced* upsert semantics | Same as Flink               |

Example (internal):

```sql
CREATE TABLE Customer (
  customerid BIGINT,
  email      STRING,
  _uuid      STRING NOT NULL METADATA FROM 'uuid',
  ts         TIMESTAMP_LTZ(3) METADATA FROM 'timestamp',
  PRIMARY KEY (customerid) NOT ENFORCED
);
```

Example (external):

```sql
CREATE TABLE kafka_json_table (
  user_id INT,
  name    STRING
) WITH (
  'connector' = 'kafka-safe',
  'topic'     = 'users',
  'format'    = 'flexible-json'
);
```

## Definition statements

### Table definition

```
TableName := SELECT … ;
```

Equivalent to a `CREATE VIEW` in SQL.

```sql
ValidCustomer := SELECT * FROM Customer WHERE customerid > 0 AND email IS NOT NULL;
```

### DISTINCT operator

```
DistinctTbl := DISTINCT SourceTbl
               ON pk_col [, …]
               ORDER BY ts_col [ASC|DESC] [NULLS LAST] ;
```

* Deduplicates a **STREAM** of changelog data into a **VERSIONED_STATE** table.
* Hint `/*+filtered_distinct_order*/` (see [hints](#-8-hint-catalogue)) may precede the statement to push filters before deduplication for optimization.

```sql
DistinctProducts := DISTINCT Products ON id ORDER BY updated DESC;
```

### Function definition

```
FuncName(arg1 TYPE [NOT NULL] [, …]) :=
  SELECT … WHERE col = :arg1 ;
```

Arguments are referenced with `:name` in the `SELECT` query. Argument definitions are identical to column definitions in `CREATE TABLE` statements.

```sql
CustomerByEmail(email STRING) := SELECT * FROM Customer WHERE email = :email;
```

### Relationship definition

```
ParentTable.RelName(arg TYPE, …) :=
  SELECT …
  FROM Child c
  WHERE this.id = c.parent_id
  [AND c.col = :arg …] ;
```

`this.` is the alias for the parent table to reference columns from the parent row.

```sql
Customer.highValueOrders(minAmount BIGINT) := SELECT * FROM Orders o WHERE o.customerid = this.id AND o.amount > :minAmount;
```

### Column-addition statement

```
TableName.new_col := expression;
```

Must appear **immediately after** the table it extends, and may reference previously added columns of the same table.


## Interfaces

The tables and functions defined in a SQRL script are exposed through an interface. The term "interface" is used generically to describe a means by which a client, user, or external system can access the processed data. The interface depends on the [configured engines](configuration.md#engines): API endpoints for servers, queries and views for databases, and topics for logs. An interface is a sink in the data processing DAG that's defined by a SQRL script.

How a table or function is exposed in the interface depends on the access type. The access type is one of the following:

| Access type | How to declare | Surface |
|-------------|----------------|---------|
| **Query** (default) | no modifier | GraphQL query / SQL view / log topic (pull) |
| **Subscription** | prefix body with `SUBSCRIBE` | GraphQL subscription / push topic |
| **None** | object name starts with `_` *or* `/*+no_query*/` hint | hidden |

Example:

```sql
HighTempAlert := SUBSCRIBE
                 SELECT * FROM SensorReading WHERE temperature > 50;
```

### CREATE TABLE

CREATE TABLE statements that define an [internal data source](#create-table-interfaces) are exposed as topics in the log, or GraphQL mutations in the server.
The input type is defined by mapping all column types to native data types of the interface schema. Computed and metadata columns are not included in the input type since those are computed on insert.

## EXPORT statement

```
EXPORT source_identifier TO sinkPath.QualifiedName ;
```

* `sinkPath` maps to a connector table definition when present, or one of the **built-in** sinks:
    * `print.*` – stdout
    * `logger.*` – uses configured logger
    * `log.*` – topic in configured log engine

```sql
EXPORT CustomerTimeWindow TO print.TimeWindow;
EXPORT MyAlerts          TO log.AlertStream;
```


## Hints

Hints live in a `/*+ … */` comment placed **immediately before** the definition they apply to.

| Hint | Form                                                                   | Applies to | Effect                                                                                                                                                       |
|------|------------------------------------------------------------------------|-----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **primary_key** | `primary_key(col, …)`                                                  | table | declare PK when optimiser cannot infer                                                                                                                       |
| **index** | `index(type, col, …)` <br/> Multiple `index(…)` can be comma-separated | table | override automatic index selection. `type` ∈ `HASH`, `BTREE`, `TEXT`, `VECTOR_COSINE`, `VECTOR_EUCLID`. <br />`index` *alone* disables all automatic indexes |
| **partition_key** | `partition_key(col, …)`                                                | table | define partition columns for sinks that support partitioning                                                                                                 |
| **vector_dim** | `vector_dim(col, 1536)`                                                | table | declare fixed vector length. This is required when using vector indexes.                                                                                     |
| **query_by_all** | `query_by_all(col, …)`                                                 | table | generate interface with *required* filter arguments                                                                                                          |
| **query_by_any** | `query_by_any(col, …)`                                                 | table | generate interface with *optional* filter arguments                                                                                                          |
| **no_query** | `no_query`                                                             | table | hide from interface                                                                                                                                          |
| **filtered_distinct_order** | flag                                                                   | DISTINCT table | eliminate updates on order column only before dedup                                                                                                          |
| **exec** | `exec(engine)`                                                         | table | pin execution engine (`streams`, `database`, `flink`, …)                                                                                                     |
| **test** | `test`                                                                 | table | marks test case, only executed with [`test` command](compiler#test-command).                                                                                 |
| **workload** | `workload`                                                             | table | retained as sink for DAG optimization but hidden from interface                                                                                              |

Example:

```sql
/*+primary_key(sensorid, time_hour), index(VECTOR_COSINE, embedding) */
SensorTempByHour := SELECT … ;
```

---

## Comments & Doc-strings

* `--` single-line comment
* `/* … */` multi-line comment
* `/** … */` **doc-string**: attached to the next definition and propagated to generated API docs.

---

## Validation rules

The following produce compile time errors:

* Duplicate identifiers (tables, functions, relationships).
* Overloaded functions (same name, different arg list) are **not** allowed.
* Argument list problems (missing type, unused arg, unknown type).
* `DISTINCT` must reference existing columns; `ORDER BY` column(s) must be monotonically increasing.
* Basetable inference failure for relationships (see below).
* Invalid or malformed hints (unknown name, wrong delimiter).

---

## Cheat Sheet

| Construct | Example                                                              |
|-----------|----------------------------------------------------------------------|
| Import package | `IMPORT ecommerceTs.* ;`                                             |
| Hidden import  | `IMPORT ecommerceTs.* AS _ ;`                                        |
| Internal table | `CREATE TABLE Orders ( … );`                                         |
| External table | `CREATE TABLE kafka_table (…) WITH ('connector'='kafka');`           |
| Table def.     | `BigOrders := SELECT * FROM Orders WHERE amount > 100;`              |
| Distinct       | `Dedup := DISTINCT Events ON id ORDER BY ts DESC;`                   |
| Function       | `OrdersById(id BIGINT) := SELECT * FROM Orders WHERE id = :id;`      |
| Relationship   | `Customer.orders := SELECT * FROM Orders WHERE this.id = customerid;` |
| Column add     | `Orders.total := quantity * price;`                                  |
| Subscription   | `Alerts := SUBSCRIBE SELECT * FROM Dedup WHERE level='WARN';`        |
| Export         | `EXPORT Alerts TO logger.Warnings;`                                  |
| Hint           | `/*+index(hash,id)*/`                                                |

## API Mapping

When a server engine is configured, the tables, relationships, and functions defined in a SQRL script map to API endpoints exposed by the server.

### GraphQL

Tables and functions are exposed as query endpoints of the same name and argument signature (i.e. the argument names and types match).
Tables/functions defined with the `SUBSCRIBE` keyword are exposed as subscriptions.
Internal table sources are exposed as mutations with the input type identical to the columns in the table excluding computed columns.

In addition, the result type of the endpoint matches the schema of the table or function. That means, each field of the result type matches a column or relationship on the table/function by name and the field type is compatible.
The field type is compatible with the column/relationship type iff:
* For scalar or collection types there is a native mapping from one type system to the other
* For structured types (i.e. nested or relationship), the mapping applies recursively.

The compiler generates the GraphQL schema automatically from the SQRL script. Add the `--api graphql` flag to the [compile command](compiler.md#compile-command) to write the schema to the `schema.graphqls` file.

You can modify the GraphQL schema and pass it as an additional argument to the compiler to fully control the interface. Any modifications must preserve the mapping described above.

### Base Tables

To avoid generating multiple redundant result types in the API interface, the compiler infers the base table.

The base table for a defined table or function is the right-most table in the relational tree of the SELECT query from the definition body if and only if that table type is equal to the defined table type. If no such table exists, the base table is the table itself.

The result type for a table or function is the result type generated for that table's base table.
Hidden columns, i.e. columns where the name starts with an underscore `_`, are not included in the generated result type.

## More Information

* Refer to the [Configuration documentation](configuration.md) for engine configuration.
* See [Command documentation](compiler.md) for CLI usage of the compiler.
* Read the [How-to guides](howto.md) for best-practices and implementation guidance.
* Follow the [Tutorials](tutorials.md) for practical SQRL examples.

For engine configuration, see **configuration.md**; for CLI usage, see **compiler.md**.# DataSQRL Configuration (`package.json` file)

DataSQRL projects are configured with one or more **JSON** files.  
Unless a file is passed explicitly to `datasqrl compile -c …`, the compiler looks for a `package.json` in the working directory; if none is found the **built-in default** (shown [here](#default-configuration)) is applied.

Multiple files can be provided; they are merged **in order** – later files override earlier ones, objects are *deep-merged*, and array values are replaced wholesale.

---

## Top-Level Keys

| Key | Type | Default | Purpose                                                        |
|-----|------|---------|----------------------------------------------------------------|
| `version` | **number** | **1** | Configuration schema version – must be `1`.                    |
| `enabled-engines` | **string[]** | `["vertx","postgres","kafka","flink"]` | Ordered list of engines that form the runtime pipeline.        |
| `engines` | **object** | – | Per-engine configuration (see below).                          |
| `compiler` | **object** | see defaults | Controls compilation, logging, and generated artefacts.        |
| `dependencies` | **object** | `{}` | Aliases for packages that can be `IMPORT`-ed from SQRL.        |
| `discovery` | **object** | `{}` | Rules for automatic table discovery when importing data files. |
| `script` | **object** | – | Points to the main SQRL script and GraphQL schema.             |
| `package` | **object** | – | Optional metadata (name, description, etc.) for publishing.    |
| `values` | **object** | `{}` | Arbitrary runtime values (e.g. `create-topics`).               |
| `test-runner` | **object** | `{"delay-sec":30}` | Integration-test execution settings.                           |

---

## 1. Engines (`engines`)

Each sub-key below `engines` must match one of the IDs in **`enabled-engines`**.

```
{
  "engines": {
    "<engine-id>": {
      "type": "<engine-id>",        // optional; inferred from key if omitted
      "config": { … },              // engine-specific knobs (Flink SQL options, etc.)
      "connectors": { … }           // templates for table sources & sinks
    }
  }
}
```

### Flink (`flink`)
| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `mode` | `"streaming"` \| `"batch"` | `"streaming"` | Execution mode used during plan compilation **and** job submission. |
| `config` | object | `{}` | Copied verbatim into the generated Flink SQL job (e.g. `"table.exec.source.idle-timeout": "5 s"`). |
| `connectors` | object | *see default list* | Connector templates (JDBC, Kafka, files, Iceberg…). Field values support variable interpolation (below). |

> **Built-in connector templates**  
> `postgres`, `postgres_log-source`, `postgres_log-sink`,  
> `kafka`, `kafka-keyed`, `kafka-upsert`,  
> `iceberg`, `localfile`, `print`.

### Kafka (`kafka`)
The default configuration only declares the engine; topic definitions are injected at **plan** time.  
Additional keys (e.g. `bootstrap.servers`) may be added under `config`.

### Vert.x (`vertx`)
A GraphQL server that routes queries to the backing database/log engines.  
No mandatory keys; connection pools are generated from the overall plan.

### Postgres (`postgres`)
No mandatory keys. Physical DDL (tables, indexes, views) is produced automatically.

### Iceberg (`iceberg`)
Used as a *table-format* engine together with a query engine such as Flink or Snowflake.

### Snowflake (`snowflake`)
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `schema-type` | `"aws-glue"` | – | External catalog implementation. |
| `catalog-name` | string | – | Glue catalog. |
| `external-volume` | string | – | Snowflake external volume name. |
| `url` | string | – | Full JDBC URL including auth params. |

---

## Compiler (`compiler`)

```jsonc
{
  "compiler": {
    "logger": "print",            // "print" | any configured log engine | "none"
    "extendedScalarTypes": true,  // expose extended scalar types in generated GraphQL
    "snapshotPath": "snapshots",  // snapshots output directory written during test runs
    "compilePlan": true,          // compile physical plans where supported

    "explain": {                  // artefacts in build/pipeline_*.*
      "visual":   true,
      "text":     true,
      "sql":      false,
      "logical":  true,
      "physical": false,
      "sorted":   true            // deterministic ordering (mostly for tests)
    },
    "output": {
      "add-uid": true,            // append a short unique id to sink tables
      "table-suffix": ""          // e.g. "-blue" to separate envs
    }
  }
}
```

---

## 3. Dependencies (`dependencies`)

```json
"dependencies": {
  "myalias": {
    "name": "folder-name",
    "version": "1",       // version identifier
    "variant": "test"     // identifier for the source variant
  }
}
```

If only `name` is given the key acts as a **local folder alias**.

---

## Discovery (`discovery`)

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `pattern` | **string (regex)** | `null` | Filters which external tables are automatically exposed in `IMPORT …` statements. Example: `"^public\\..*"` |

---

## Script (`script`)

| Key | Type | Description |
|-----|------|-------------|
| `main` | **string** | Path to the main `.sqrl` file. |
| `graphql` | **string** | Optional GraphQL schema file (defaults to `schema.graphqls`). |

---

## Package Metadata (`package`)

| Key | Required | Description |
|-----|----------|-------------|
| `name` | **yes** | Reverse-DNS style identifier (`org.project.module`). |
| `description` | no | Short summary. |
| `license` | no | SPDX license id or free-text. |
| `homepage` | no | Web site. |
| `documentation` | no | Docs link. |
| `topics` | no | String array of tags/keywords. |

---

## Test-Runner (`test-runner`)

| Key | Type | Default | Meaning |
|-----|------|---------|---------|
| `delay-sec` | **number** | `30` | Wait between data-load and snapshot. Set `-1` to disable. |
| `required-checkpoints` | **number** | `0` | Minimum completed Flink checkpoints before assertions run (requires `delay-sec = -1`). |
| `mutation-delay` | **number** | `0` | Pause (s) between mutation queries. |

---

## Values (`values`)

Arbitrary key/value pairs that are exposed to the runtime launcher.  
The **default launcher** recognises:

| Key | Type | Description |
|-----|------|-------------|
| `create-topics` | **string[]** | Kafka topics to create before tests start. |

---

## Template & Environment Variables

* **Environment variables** use `${VAR_NAME}` — resolved by the DataSQRL launcher at runtime.  
  Example: `${JDBC_PASSWORD}`.
* **SQRL variables** use `${sqrl:<identifier>}` and are filled automatically by the compiler, mostly inside connector templates.  
  Common identifiers include `table-name`, `original-table-name`, `filename`, `format`, and `kafka-key`.

Unresolved `${sqrl:*}` placeholders raise a validation error.

---

## Default Configuration

The built-in fallback (excerpt - full version [here](https://github.com/DataSQRL/sqrl/blob/main/sqrl-tools/sqrl-config/src/main/resources/default-package.json)):

```jsonc
{
  "version": 1,
  "enabled-engines": ["vertx","postgres","kafka","flink"],
  "engines": {
    "flink": {
      "connectors": {
        "postgres": { "connector": "jdbc-sqrl", … },
        "kafka":   { "connector": "kafka", … },
        "kafka-keyed": { … },
        "kafka-upsert": { … },
        "localfile": { … },
        "iceberg": { … },
        "print": { "connector": "print" }
      }
    },
    "snowflake": {
      "schema-type": "aws-glue",
      "catalog-name": "${SNOWFLAKE_CATALOG_NAME}",
      "external-volume": "${SNOWFLAKE_EXTERNAL_VOLUME}",
      "url": "jdbc:snowflake://${SNOWFLAKE_ID}.snowflakecomputing.com/?…"
    }
  },
  "test-runner": { "delay-sec": 30 }
}
```# DataSQRL Command

The DataSQRL command compiles, runs, and tests SQRL scripts.

You invoke the DataSQRL command in your terminal or command line. Choose your operating system below or use Docker which works on any machine that has Docker installed.

## Installation

Always pull the latest Docker image to ensure you have the most recent updates:

```bash
docker pull datasqrl/cmd:latest
```

### Global Options
All commands support the following global options:

|Option/Flag Name	|Description|
|--------------|---------------|
|-c or --config|	Specifies the path to one or more package configuration files. Contents of multiple files are merged in the specified order. Defaults to package.json in the current directory, generating a default configuration if none exists.|

Note, that most commands require that you either specify the SQRL script (and, optionally, a GraphQL schema) as command line arguments or use the `-c` option to specify a project configuration file that allows you to configure all aspects of the project. See the [configuration documentation](configuration.md) for more details.

## Compile Command

The compile command processes a SQRL script and, optionally, an API specification, into a deployable data pipeline.
The compile command stages all files needed by the compiler in the `build` directory and output the created deployment artifacts for all engines in the `build/deploy` folder.



```bash
docker run --rm -v $PWD:/build datasqrl/cmd compile myscript.sqrl
```
or
```bash
docker run --rm -v $PWD:/build datasqrl/cmd compile -c package.json
```

Note, that you need to mount the current directory (`$PWD` or `${PWD}` on windows with Powershell) to the `/build`
directory for file access in docker.


|Option/Flag Name| 	Description                                                                                                                  |
|--------------|-------------------------------------------------------------------------------------------------------------------------------|
|-a or --api	| Generates an API specification (GraphQL schema) in the file schema.graphqls. Overwrites any existing file with the same name. |
|-t or --target	| Directory to write deployment artifacts, defaults to build/plan.                                                              |

Upon successful compilation, the compiler writes the data processing DAG that is planned from the SQRL script into the file `build/pipeline_explain.txt` and a visual representation to `build/pipeline_visual.html`. Open the latter file in your browser to inspect the data processing DAG.


## Run Command

The run command compiles and runs the generated data pipeline in docker.


```bash
docker run -it -p 8888:8888 -p 8081:8081 -p 9092:9092 --rm -v $PWD:/build datasqrl/cmd run myscript.sqrl
```

Note, the additional port mappings to access the individual data systems that are running the pipeline.

The run command uses the following engines:
* Flink as the stream engine: The Flink cluster is accessible through the WebUI at [http://localhost:8081/](http://localhost:8081/).
* Postgres as the transactional database engine
* Iceberg+DuckDB as the analytic database engine
* RedPanda as the log engine: The RedPanda cluster is accessible on port 9092 (via Kafka command line tooling).
* Vertx as the server engine: The GraphQL API is accessible at [http://localhost:8888/graphiql/](http://localhost:8888/graphiql/).

### Data Access

DataSQRL runs up the data systems listed above and maps your local directories for data access. To access this data in your DataSQRL jobs during local execution use:
* `${PROPERTIES_BOOTSTRAP_SERVERS}` to connect to the Redpanda Kafka cluster
* `${DATA_PATH}/` to reference `.jsonl` or `.csv` data in your project.

This allows DataSQRL to map connectors correctly and also applies to [testing](#test-command).

### Data Persistence

To preserve inserted data between runs, mount a directory for RedPanda to persist the data to:


```bash
docker run -it -p 8888:8888 -p 8081:8081 -p 9092:9092 --rm -v /mydata/project:/data/redpanda -v $PWD:/build datasqrl/cmd run myscript.sqrl
```

The volume mount contains the data written to the log engine and persists it to the local `/mydata/project` directory where you want to store the data (adjust as needed and make sure the directory exists).


When you terminate (via `CTRL-C`) and re-run your SQRL project, it will replay prior data.

### Deployment 

The run command is primarily used for local development and quick iteration cycles. It supports small-scale deployments.
For large-scale deployments, we recommend that you run the generated pipeline in Kubernetes by extending our [Kubernetes setup](https://github.com/DataSQRL/sqrl-k8s).

If you prefer a managed service, you can use [DataSQRL Cloud](https://www.datasqrl.com/) for automated and optimized deployments. Alternatively, you can deploy the generated deployment artifacts in the `build/plan` directory using available managed services by your preferred cloud provider.

## Test Command

The test command compiles and runs the data pipeline, then executes the provided test API queries and API endpoints for all tables annotated with `/*+test */` to snapshot the results.

When you first run the test command or add additional test cases, it will create the snapshots and fail. All subsequent runs of the test command compare the results to the previously snapshotted results and succeed if the results are identical, else fail.

```bash
docker run --rm -v $PWD:/build datasqrl/cmd test
```

Options for the Test Command:

| Option/Flag Name  | 	Description                                            |
|-------------------|---------------------------------------------------------|
| -s or --snapshots | 	Path to the snapshot files. Defaults to `snapshots`.   |
| --tests           | 	Path to test graphql query files. Defaults to `tests`. |

The `tests` directory contains GraphQL queries that are executed against the API of the generated data pipeline. 

### Test Execution Overview

Subscriptions are registered first. This ensures that any incoming data events are captured as soon as they occur.

Next, mutations are executed in alphabetical order. This controlled ordering allows predictable state changes during testing.

Queries are executed after all mutations have been applied. This step retrieves the system state resulting from the preceding operations.

Once all queries complete, the subscriptions are terminated and the data collected during their active phase is assembled into snapshots.

:::warning
Subscriptions can only be tested in conjunction with mutations at this time.
:::# Key DataSQRL Concepts

This document explains some of the key concepts in streaming data processing.

## Time Handling

Time is the most important concept in DataSQRL because it determines how data streams are processed.

For stream processing, it is useful to think of time as a timeline that stretches from the past through the present and into the future. The blue line in the picture below visualizes a timeline.

<img src="/img/docs/timeline.svg" alt="SQRL Timeline" width="100%" />

The blue vertical bar on the timeline represents the present. The present moment continuously advances on the timeline.

Each stream record processed by the system (shown as grey circles) is associated with a point on the timeline before the present. We call this point in time the **event time** of a stream record. The event time can be the time when an event occurred, a metric was observed, or a change happened. It is a fixed point in time on the timeline and it must be older than the present.

However, records may come in out of order. Or we might be processing records for multiple different systems (or different partitions of the same system) and hence the records can have different event time.

To synchronize the disparate event times, we need another concept: the watermark. The watermark is shown as the orange line on the timeline and it provides a simple but powerful guarantee: there will be no more records older than the watermark.
Hence, the watermark is always smaller than the present. It may be significantly older. The watermark allows the streaming processor to make progress in time, because it is guaranteed to not encounter older records than the watermark which would require it to revise previously computed data.

That's why it is important to carefully define the watermark. In most cases, the watermark is defined relative to records that have been received, for instance setting the watermark to 5 minutes older than the newest record's event time. This is called a bounded out-of-orderedness watermark, which means that while we cannot guarantee that records arrive in order we can guarantee that the out of order records will be at most 5 minutes older.

Watermarks play a key role in synchronizing data across joins, closing time windows, and combining streams.

In DataSQRL, you define the watermark for external sources. For tables exposed as mutations in the API, DataSQRL handles the watermarks for you.
# Connecting External Data Sources and Sinks

Use `CREATE TABLE` statements to connect external data sources and sinks with your SQRL script using the `WITH` clause to provide connector configuration.

DataSQRL uses Apache Flink connectors and formats. To find a connector for your data system, use:

* **[The Official Apache Flink connectors](https://nightlies.apache.org/flink/flink-docs-release-1.19/docs/connectors/table/overview/)** for Kafka, Filesystem, Kinesis, and many more.
* **DataSQRL provided connectors**
  * **[Safe Kafka Source Connectors](https://github.com/DataSQRL/flink-sql-runner?tab=readme-ov-file#dead-letter-queue-support-for-kafka-sources)** which support dead-letter queues for faulty messages.
* **[Apache Flink CDC connectors](https://nightlies.apache.org/flink/flink-docs-release-1.19/docs/connectors/flink-sources/overview)** for Postgres, MySQL, Oracle, SqlServer, and other databases.

## Connector Management

The best practice for managing connectors in your DataSQRL project is to create a folder for each system that you are connecting to and place all source or sink `CREATE TABLE` statements in separate files ending in `.table.sql` in that folder. You can then import from and export to those sources and sinks in the SQRL script.

For example, to ingest data from the `User` and `Transaction` topics of a Kafka cluster, you would:
1. Create a sub-directory `kafka-sources` in your project directory that contains your SQRL script
2. Create two files `user.table.sql` and `transaction.table.sql`.
3. Each file contains a `CREATE TABLE` statement that defines columns for each field in the message and a `WITH` clause that contains the connector configuration. They will look like this:
```sql
CREATE TABLE User (
  user_id BIGINT,
  user_name STRING,
  last_updated TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
  WATERMARK FOR last_updated AS last_updated - INTERVAL '1' SECOND
  WATERMARK 
) WITH (
  'connector' = 'kafka',
  'topic' = 'user',
  'properties.bootstrap.servers' = 'localhost:9092',
  'properties.group.id' = 'user-consumer-group',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'avro',
);
```
4. Import those sources into your SQRL script with `IMPORT kafak-sources.User;`
5. Keep sources and sinks in separate folders (e.g. `kafka-sink`)

By following this structure, you modularize your sources and sinks from your processing logic which makes it easier to read and maintain.

It also allows you to switch out sources and sinks with DataSQRL's [dependency management](configuration#dependencies) which is useful for local development and testing. For example, you typically use different sources and sinks for local development, testing, QA, and production. Those could live in their respective source folders and be resolved through the [dependency section](configuration#dependencies) in the package configuration.

## External Schemas

When ingesting data from external systems, the schema is often defined in or by those systems. For example, avro is a popular schema language for encoding messages in Kafka topics. It can be very cumbersome to convert that schema to SQL and maintain that translation.

With DataSQRL, you can place the avro schema next to the table definition file using the table name.
Following the example above and assuming that the schema for the `User` topic is `user.avsc`, you would place that file next to the `user.table.sql` file and DataSQRL automatically pulls in the schema, so the CREATE TABLE statement simplifies to only defining the metadata, watermark, and connector:
```sql
CREATE TABLE User (
  last_updated TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp',
  WATERMARK FOR last_updated AS last_updated - INTERVAL '1' SECOND
  WATERMARK 
) WITH (
  'connector' = 'kafka',
  'topic' = 'user',
  'properties.bootstrap.servers' = 'localhost:9092',
  'properties.group.id' = 'user-consumer-group',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'avro',
);
```# How-To Guides

Practical guides for developing data pipelines with DataSQRL

## Project Structure

We recommend the following project structure to support testing and deploying to multiple environments:

```text
project-root/
├── sources-prod/                  <-- contains source connectors for prod
├── sources-testdata/              <-- contains test data
├── snapshots/                     <-- snapshots for test cases, generated by DataSQRL
├── tests/                         <-- (optional) GraphQL test queries
├── components.sqrl                <-- table definitions imported into main script
├── mainscript.sqrl
├── mainscript_package_prod.json   <-- configuration for prod
└── mainscript_package_test.json   <-- configuration for testing
```

* Create one folder for each collection of data sources. Sources that represent the same type of data but different environments (test vs prod) have the same prefix.
* Create one package.json [configuration file](configuration.md) for each environment that references the same main script but maps the data sources differently in the `dependencies` section of the configuration and (optionally) uses different engines and configurations.
* By default, DataSQRL uses `tests` and `snapshots` directories. If you have multiple test suites or run the same tests with different sources, append a distinguishing suffix (e.g. `-api` or `-regression`) to both directory names and specify them explicitly in the configuration file or via [compiler flags](compiler.md#test-command).

## Testing

DataSQRL supports [running automated tests](compiler#test-command) for your SQRL pipeline by annotating test cases with the `/*+test */` hint or placing test queries in the `tests` folder (or any other folder that's passed via the `--tests` command option).

The best practice for writing test cases is to [modularize](connectors#connector-management) your sources so that you dynamically link different sources for local development, testing, and production. In many cases, you can use the same sources for testing and local development in a single folder.

That data should contain explicit event timestamps for all records. That enables completely deterministic test cases. It also supports reproducing failure scenarios that you experienced in production as local test cases by using the data that caused the failure with the original timestamp. That way, you don't have to externally simulate certain sequences of events that caused the failure in the first place.

In addition, it allows you to build up a repository of failures and edge cases that gets executed automatically to spot regressions.

## Script Imports

If your main script gets too big, or you want to reuse table definitions across multiple scripts, move the definitions to a separate SQRL script and import it into the main script.

### Inline Script Imports

Inline imports place table and function definitions from another script into the current scope and requires
that table and function names do not clash with those in the importing script.

```sql
IMPORT myscript.*;
```
This statement imports all tables and functions from a SQRL script called `myscript.sqrl` in the local folder.

## Data Discovery

DataSQRL automatically generates table definitions with connector configuration and schemas for json-line files (with extension `.jsonl`) and csv files (with extension `.csv`) within the project directory. This makes it easy to import data from such files into a SQRL project.

For example, to import data from a file `orders.jsonl` in the folder `mydata` you write:
```sql
IMPORT mydata.orders;
```

When you run the compiler, it will create the table configuration file `orders.table.sql` which you can then import like any other source. The compiler reads the file and auto-discovers the schema.

To disable automatic discovery of data for a directory, place a file called `.nodiscovery` into that directory.

## Manual Subgraph Elimination with Noop Function

Sometimes the Flink optimizer is too smart for its own good and will push down predicates that make common subgraph identification impossible. That can result in much larger job graphs and poor performance or high state maintenance.

To inhibit predicate pushdown, SQRL uses the `noop` function that takes an arbitrary list of argument and always returns true.
As such, the function serves no purpose other than making it impossible for the optimizer to push down predicates.



# Functions

## System Functions

SQRL supports all of [Flink's built-in system functions](https://nightlies.apache.org/flink/flink-docs-release-1.19/docs/dev/table/functions/systemfunctions/).

SQRL adds [system functions](functions-docs/function-docs/system-functions) with support for:
* a binary JSON type (JSONB) to represent semi-structured data efficiently.
* a vector type to represent embeddings.
* text manipulation and full text search.

System functions are always available and do not need to be imported. Take a look at the [full list of SQRL system function](functions-docs/function-docs/system-functions).

## Function Libraries

SQRL includes [standard libraries](functions-docs/function-docs/library-functions) that can be imported into a SQRL script as follows:

```sql
IMPORT stdlib.math;
```
Imports all functions from the `math` library into the script. Replace `math` with the library you wish to import.

```sql
IMPORT stdlib.math.hypot AS hypotenuse;
```
Imports a single function `hypot` from the `math` library under the name `hypotenuse`. The renaming with `AS` is optional and is omitted when you want to use the original name.

Check out the [full list of function libraries](functions-docs/function-docs/library-functions).


## User Defined Functions

Users can define custom functions and import them into a SQRL script. 

### Java

To create a new function package, first create a sub-folder `myjavafunction` in the directory of the script where you want to import the functions.
Inside that package, create a java project which implements a [Flink function](https://nightlies.apache.org/flink/flink-docs-release-1.19/docs/dev/table/functions/udfs/).
Annotate the function with `@AutoService` and the Flink function that it extends so the function can be discovered by the compiler.

Compile the java project into a jar file and import it into the SQRL script via:
```sql
IMPORT myjavafunction.target.MyScalarFunction;
```

Check out this [complete example](https://github.com/DataSQRL/datasqrl-examples/tree/main/user-defined-function).


### JavaScript

Support for JavaScript functions is currently being implemented and is targeted for the 0.7 release.

### Python

Support for Python functions is currently being implemented and is targeted for the 0.7 release.# Function Libraries

The following library functions can be imported for additional functionality:
* [Advanced Math](#math)
* [OpenAI](#openai)

## Math

Functions for advanced mathematics under the `math` package.

| **Function Name**                   | **Description**                                                                                                                                                         |
|-------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **cbrt(double)**                    | Calculates the cube root of a number. For example, `cbrt(27.0)` returns `3.0`, which is the cube root of 27.0.                                                          |
| **copy_sign(double, double)**       | Returns the first argument with the sign of the second argument. For example, `copy_sign(2.0, -3.0)` returns `-2.0`.                                                    |
| **expm1(double)**                   | Calculates e^x - 1 with better precision for small values. For example, `expm1(0.0)` returns `0.0`, as `e^0 - 1 = 0`.                                                   |
| **hypot(double, double)**           | Computes sqrt(x² + y²) without intermediate overflow or underflow. For example, `hypot(3.0, 4.0)` returns `5.0`, which is the hypotenuse of a 3-4-5 triangle.            |
| **log1p(double)**                   | Computes the natural logarithm of 1 + x (log(1 + x)) accurately for small x. For example, `log1p(0.0)` returns `0.0` as `log(1 + 0) = 0`.                              |
| **next_after(double, double)**      | Returns the next floating-point number towards the direction of the second argument. For example, `next_after(1.0, 2.0)` returns the next representable number after 1.0. |
| **scalb(double, bigint)**           | Multiplies a floating-point number by 2 raised to the power of an integer. For example, `scalb(1.0, 3)` returns `8.0` as `1.0 * 2^3 = 8.0`.                             |
| **ulp(double)**                     | Returns the size of the unit in the last place (ULP) of the argument. For example, `ulp(1.0)` returns the ULP of 1.0.                                                   |
| **binomial_distribution(bigint, double, bigint)** | Calculates the probability of obtaining a number of successes in a fixed number of trials for a binomial distribution. For example, `binomial_distribution(10, 0.5, 5)` returns the probability of 5 successes out of 10 trials with a 50% success rate. |
| **exponential_distribution(double, double)** | Evaluates the probability density or cumulative distribution of an exponential distribution. For example, `exponential_distribution(1.0, 2.0)` returns the exponential distribution's probability for a given rate and time. |
| **normal_distribution(double, double, double)** | Evaluates the cumulative distribution function for a normal (Gaussian) distribution. For example, `normal_distribution(0.0, 1.0, 1.0)` returns the probability for a standard normal distribution with mean 0 and standard deviation 1. |
| **poisson_distribution(double, bigint)** | Evaluates the probability mass function of a Poisson-distributed random variable. For example, `poisson_distribution(1.0, 5)` returns the probability of observing 5 events when the average event rate is 1.0. |


## OpenAI

OpenAI API function under the `openai` package.

You can use these UDFs in your SQRL scripts to perform tasks such as text completion, extraction, and embedding, leveraging the power of OpenAI models.

For each function it is required to set the `OPENAI_API_KEY` environment variable with your OpenAI API key.

| **Function Name**                   | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
|-------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **completions(String prompt, String model_name)**        | Generates a completion for the given prompt using the specified OpenAI model. For example, `completions('What is AI?', 'gpt-4o')` returns a possible response to the prompt.                                                                                                                                                                                                                                                                                         |
| **completions(String prompt, String model_name, Integer maxOutputTokens)**       | Generates a completion for the given prompt using the specified OpenAI model, with an upper limit on the number of output tokens.                                             For example, `completions('What is AI?', 'gpt-4o', 100)` returns a possible response to the prompt, limited to 100 characters.                                                                                                                                                         |
| **completions(String prompt, String model_name, Integer maxOutputTokens, Double temperature)**       | Generates a completion for the given prompt using the specified OpenAI model, with an upper limit on the number of output tokens and a specified temperature. For example, `completions('What is AI?', 'gpt-4o', 100, 0.5)` returns a possible response to the prompt, limited to 100 characters and weighted by a temperature of 0.5.                                                                                                                               |
| **completions(String prompt, String model_name, Integer maxOutputTokens, Double temperature, Double topP)**       | Generates a completion for the given prompt using the specified OpenAI model, with an upper limit on the number of output tokens, a specified temperature, and a specified top-p value. For example, `completions('What is AI?', 'gpt-4o', 100, 0.5, 0.9)` returns a possible response to the prompt, limited to 100 characters, weighted by a temperature of 0.5, and with a top-p value of 0.9.                                                                    |
| **extract_json(String prompt, String model_name)**        | Extracts JSON data from the given prompt using the specified OpenAI model. For example, `extract_json('What is AI?', 'gpt-4o')` returns any relevant JSON data for the prompt.                                                                                                                                                                                                                                                                                                               |
| **extract_json(String prompt, String model_name, Double temperature)**       | Extracts JSON data from the given prompt using the specified OpenAI model and a specified temperature. For example,                                                             `extract_json('What is AI?', 'gpt-4o', 0.5)` returns any relevant JSON data for the prompt, weighted by a temperature of 0.5.                                                                                                                                                                                |
| **extract_json(String prompt, String model_name, Double temperature, Double topP)**       | Extracts JSON data from the given prompt using the specified OpenAI model, with a specified temperature and top-p value.                                                                                                                                                                                       For example, `extract_json('What is AI?', 'gpt-4o', 0.5, 0.9)` returns any relevant JSON data for the prompt, weighted by a temperature of 0.5 and with a top-p value of 0.9. |
| **vector_embedd(String text, String model_name)**        | Embeds the given text into a vector using the specified OpenAI model. For example, `vector_embedd('What is AI?', 'text-embedding-ada-002')` returns a vector representation of the text.                                                                                                                     |# System Functions

The following system functions are added to [Flink's built-in system functions](https://nightlies.apache.org/flink/flink-docs-release-1.19/docs/dev/table/functions/systemfunctions/) to support additional types and functionality.

## JSONB Functions

The binary JSON type (jsonb) uses a more efficient representation of JSON data and allows for native support of JSON in formats and connectors, like mapping to Postgre's JSONB column type.

The following system functions create and manipulate binary JSON data.

| Function Name         | Description                                                                                          | Example Usage                                                                                     |
|-----------------------|------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| `to_jsonb`            | Parses a JSON string or Flink object (e.g., `Row`, `Row[]`) into a JSON object.                      | `to_jsonb('{"name":"Alice"}')` → JSON object                                                      |
| `jsonb_to_string`     | Serializes a JSON object into a JSON string.                                                         | `jsonb_to_string(to_jsonb('{"a":1}'))` → `'{"a":1}'`                                               |
| `jsonb_object`        | Constructs a JSON object from key-value pairs. Keys must be strings.                                 | `jsonb_object('a', 1, 'b', 2)` → `{"a":1,"b":2}`                                                   |
| `jsonb_array`         | Constructs a JSON array from multiple values or JSON objects.                                        | `jsonb_array(1, 'a', to_jsonb('{"b":2}'))` → `[1,"a",{"b":2}]`                                     |
| `jsonb_extract`       | Extracts a value from a JSON object using a JSONPath expression. Optionally specify default value.   | `jsonb_extract(to_jsonb('{"a":1}'), '$.a')` → `1`                                                  |
| `jsonb_query`         | Executes a JSONPath query on a JSON object and returns the result as a JSON string.                  | `jsonb_query(to_jsonb('{"a":[1,2]}'), '$.a')` → `'[1,2]'`                                          |
| `jsonb_exists`        | Returns `TRUE` if a JSONPath exists within a JSON object.                                            | `jsonb_exists(to_jsonb('{"a":1}'), '$.a')` → `TRUE`                                                |
| `jsonb_concat`        | Merges two JSON objects. If keys overlap, the second object's values are used.                       | `jsonb_concat(to_jsonb('{"a":1}'), to_jsonb('{"b":2}'))` → `{"a":1,"b":2}`                         |
| `jsonb_array_agg`     | Aggregate function: accumulates values into a JSON array.                                            | `SELECT jsonb_array_agg(col) FROM tbl`                                                             |
| `jsonb_object_agg`    | Aggregate function: accumulates key-value pairs into a JSON object.                                  | `SELECT jsonb_object_agg(key_col, val_col) FROM tbl`                                               |

## Vector Functions

The vector type supports efficient representation of large numeric vector, e.g. for embeddings. 

Use the following system functions to manipulate, convert, and aggregate vectors.

| Function Name           | Description                                                                 | Example Usage                        |
|------------------------|-----------------------------------------------------------------------------|-------------------------------------|
| `cosine_similarity`    | Computes cosine similarity between two vectors.                             | `cosine_similarity(vec1, vec2)`     |
| `cosine_distance`      | Computes cosine distance between two vectors (1 - cosine similarity).       | `cosine_distance(vec1, vec2)`       |
| `euclidean_distance`   | Computes the Euclidean distance between two vectors.                        | `euclidean_distance(vec1, vec2)`    |
| `double_to_vector`     | Converts a `DOUBLE[]` array into a `VECTOR`.                                | `double_to_vector([1.0, 2.0, 3.0])` |
| `vector_to_double`     | Converts a `VECTOR` into a `DOUBLE[]` array.                                | `vector_to_double(vec)`             |
| `center`               | Computes the centroid (average) of a collection of vectors. Aggregate function. | `SELECT center(vecCol) FROM vectors`|

## Text Functions

Functions for text manipulations and search.

| Function Name                    | Description                                                                                                                                                                                                                                                                                              |
|----------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `format(String, String...)`      | A function that formats text based on a format string and variable number of arguments. It uses Java's `String.format` method internally. If the input text is `null`, it returns `null`. For example, `Format("Hello %s!", "World")` returns "Hello World!".                                            |
| `text_search(String, String...)` | Evaluates a query against multiple text fields and returns a score based on the frequency of query words in the texts. It tokenizes both the query and the texts, and scores based on the proportion of query words found in the text. For example, `text_search("hello", "hello world")` returns `1.0`. |# Getting Started with DataSQRL

We are going to build a data pipeline with SQRL that:
* ingests statistics on user requests for the token consumption
* aggregates token consumption by user
* and provides a push-based alert for high token consumption

<!-- Add video tutorial -->

## Define SQRL Script

```sql title=usertokens.sqrl
/*+no_query */
CREATE TABLE UserTokens (
    userid BIGINT NOT NULL,
    tokens BIGINT NOT NULL,
    request_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp'
);

/*+query_by_all(userid) */
TotalUserTokens := SELECT userid, sum(tokens) as total_tokens,
                          count(tokens) as total_requests
                   FROM UserTokens GROUP BY userid;

UsageAlert := SUBSCRIBE SELECT * FROM UserTokens WHERE tokens > 100000;
```

* **UserTokens** defines the input data we use for data collection which is exposed as a mutation endpoint. The mutation endpoint has the same schema as the table minus the metadata columns which are automatically inserted from the context. In this example, the `timestamp` metadata refers to the timestamp of the mutation request which gets stored in the `request_time` column.
* **TotalUserTokens** defines a derived table that aggregates the user tokens by `userid`. The `query_by_all(userid)` hint specifies that this table is accessible through a query endpoint that requires a `userid` argument.
* **UsageAlert** defines a table that contains all requests where the token consumption exceeds `100,000`. The `SUBSCRIBE` keyword means that this table is exposed as a subscription in the API.

The architecture of the pipeline defined by the SQRL script looks as follows:
![Initial Pipeline Architecture](/img/diagrams/getting_started_diagram1.png)

## Run SQRL Script

Create a file `usertokens.sqrl` with the content above in a new directory:
```bash
mkdir myproject; cd myproject;
vi usertokens.sqrl;
```

We can now execute the SQRL script with the compiler:

```bash
docker run -it --rm -p 8888:8888 -p 8081:8081 -p 9092:9092 -v $PWD:/build datasqrl/cmd:latest run usertokens.sqrl
``` 
(Use `${PWD}` in Powershell on Windows).

Note, that we are mapping the local directory so the compiler has access to the script. We are also mapping a number of ports, so we have access to the API and visibility into the pipeline.



## Access the API

The pipeline is exposed through a GraphQL API that you can access at  [http://localhost:8888/graphiql/](http://localhost:8888/graphiql/) in your browser.

To add user token requests, we run the following mutation:
```graphql
mutation {
 UserTokens(event: {userid: 1, tokens:500}) {
  request_time
}
}
```
Copy the query into the left-hand panel and click on the "play" button to see the result.

To query the aggregated statistics, run the following query:
```graphql
{
 TotalUserTokens(userid:1) {
  total_tokens
  total_requests
}
}
```

To get a push-alert for high token consumption, first run the following subscription:
```graphql
subscription {
  UsageAlert {
    userid
    tokens
  }
}
```
*While* the subscription is running, open a new browser tab for [GraphiQL](http://localhost:8888/graphiql/) and execute this mutation:
```graphql
mutation {
 UserTokens(event: {userid: 2, tokens:400000}) {
  request_time
}
}
```
If you toggle back to the subscription tab, you should see the request.

Once you are done, terminate the pipeline with `CTRL-C`.

## Extend the SQRL Script

We are going to add information about the user so we can associate token consumption with the organization the user is part of.

To demonstrate how to integrate external data sources, we assume that the user information is stored in another system and that we consume a CDC stream of that data. We are going to simulate that CDC stream in the following JSON file:

```json lines
{"userid":  1, "orgid":  2, "last_updated": "2025-04-20T18:12:00.000Z"}
{"userid":  2, "orgid":  2, "last_updated": "2025-04-21T11:23:00.000Z"}
{"userid":  3, "orgid":  1, "last_updated": "2025-04-24T07:15:00.000Z"}
{"userid":  1, "orgid":  2, "last_updated": "2025-04-25T19:34:00.000Z"}
{"userid":  2, "orgid":  1, "last_updated": "2025-04-25T21:47:00.000Z"}
```
Create the file `local-data/userinfo.jsonl` in a new sub-directory `local-data`.

Now add the following to your `usertokens.sqrl` script:
```sql
IMPORT local-data.userinfo AS _UserInfo;

_CurrentUserInfo := DISTINCT _UserInfo ON userid ORDER BY last_updated DESC;

_EnrichedUserTokens := SELECT t.*, u.orgid FROM UserTokens t
   JOIN _CurrentUserInfo FOR SYSTEM_TIME AS OF t.request_time u ON u.userid = t.userid;

TotalOrgTokens := SELECT orgid, sum(tokens) as total_tokens,
                         count(tokens) as total_requests
                  FROM _EnrichedUserTokens GROUP BY orgid;

TotalOrgTokensByRange( minTokens BIGINT NOT NULL, maxTokens BIGINT NOT NULL) :=
    SELECT * FROM TotalOrgTokens
    WHERE total_tokens >= :minTokens AND total_tokens <= :maxTokens;
```

* **_UserInfo**: We import the data from the `userinfo.jsonl` file with the IMPORT statement. Note that we are renaming the table to start with an underscore which "hides" to table since we don't want this data exposed in the API.
* **_CurrentUserInfo**: The imported data is a CDC stream. To get the most recent information for each user, we deduplicate the data with the `DISTINCT` statement.
* **_EnrichedUserTokens** enriches the stream of requests with the user information through a **temporal join** which ensures that we join the stream with the user info that was valid at the point of time when the stream record gets processed. This ensures data consistency.
* **TotalOrgTokens** aggregates the total tokens by organization.
* **TotalOrgTokensByRange** defines a query endpoint for the **TotalOrgTokens** table to query by token range. This function defines two parameters `minTokens` and `maxTokens` and references those in the query using the `:` parameter prefix.

You can run the script and access the API like we did above.

Note, that when you compile or run the script, the compiler automatically created a connector table from the data in the `local-data/userinfo.table.sql` file. DataSQRL can automatically infer the schema from JSONL or CSV files and generate connectors.

You can also define connectors manually to ingest data from Kafka, Kinesis, Postgres, Apache Iceberg, and many other sources. Check out the [Connectors Documentation](connectors.md) to learn how to ingest data from and sink data to many external data systems.

## Testing

We can add tests to a SQRL script to ensure it produces the right data, automate those tests to avoid regressions, and enable deployment automation in CI/CD pipelines.

Tests can be added directly to the SQRL script with the `/*+test */` hint:
```sql
/*+test */
UserTokensTest := SELECT * FROM TotalUserTokens ORDER BY userid ASC;

/*+test */
OrgTokensTest := SELECT * FROM TotalOrgTokens ORDER BY orgid ASC;
```

Add those two test cases to the `usertokens.sqrl` script. 

We can also add tests as GraphQL queries that get executed against the API. For our example, we need to add a mutation query - otherwise there is no input data to test against.

Add the folder `tests` in the root of the project and add the following mutation query in the file `tests/addTokens-mutation.graphql` to add some test data:
```graphql
mutation {
    Token1: UserTokens(event: {userid: 1, tokens: 500}) {
        userid
    }
    Token2: UserTokens(event: {userid: 2, tokens: 100}) {
        userid
    }
    Token3: UserTokens(event: {userid: 2, tokens: 200}) {
        userid
    }
    Token4: UserTokens(event: {userid: 1, tokens: 700}) {
        userid
    }
}
```

Now you can run the test cases with the command:
```bash
docker run -it --rm -v $PWD:/build datasqrl/cmd:latest test usertokens.sqrl 
```

When you first run new tests, the test runner creates snapshots for each test case. When you run the test again, it will succeed if the snapshots match or fail if they don't.

## Deployment

To build the deployment assets in the for the data pipeline, execute
```bash
docker run --rm -v $PWD:/build datasqrl/cmd:latest compile usertokens.sqrl
``` 
The `build/deploy` directory contains the Flink compiled plan, Kafka topic definitions, PostgreSQL schema and view definitions, server queries, and GraphQL data model.

The `build` directory contains two files that are useful to visualize, inspect, and document the data pipelines you create with DataSQRL.
* `pipeline_visual.html` is a visual representation of the entire data pipeline. Open this file in your browser.
* `pipeline_explain.txt` contains a textual representation of the pipeline DAG that DataSQRL generates.

![DataSQRL Pipeline Visualization](/img/screenshots/dag_example.png)

The picture above is the visualization of the pipeline we have build thus far. You can click on the individual nodes in the graph to inspect the schema, logical, and physical plan.

## Customize GraphQL Schema

To inspect the GraphQL API that DataSQRL generates from the SQRL script, execute:
```bash
docker run --rm -v $PWD:/build datasqrl/cmd:latest compile usertokens.sqrl --api graphql
``` 
This creates a file called `schema.graphqls` in the project root directory.

To make adjustments to the GraphQL schema, rename the file to `usertokens.graphqls` before making modifications: removing fields, changing default values, renaming types, etc. To build the project with the adjusted schema, execute:

```bash
docker run --rm -v $PWD:/build datasqrl/cmd:latest compile usertokens.sqrl usertokens.graphqls
```

## Next Steps

Congratulations, you made the first big step toward building production-grade data pipelines the easy way.
Next, check out:
* **[Full Documentation](intro.md)** for the complete reference, language spec, and more. 
* **[Tutorials](tutorials.md)** if you prefer learning by doing.