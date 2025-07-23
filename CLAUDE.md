# DataSQRL Examples Repository

This repository contains multiple DataSQRL (SQRL) projects demonstrating various use cases and patterns for reactive data processing.

## Repository Overview

DataSQRL is a SQL extension that adds incremental data processing capabilities. SQRL scripts compile into data pipelines that can run across multiple engines (Flink, Kafka, Postgres, etc.).

## Project Structure

Each directory contains a complete DataSQRL example with:
- `.sqrl` files: Main SQRL scripts defining data processing logic
- `package.json` or `*_package_*.json`: Configuration files for different environments
- `*-testdata/` or `testdata/`: Test data sources
- `*-api/`, `*-kafka/`, etc.: Connector definitions for different systems
- `snapshots/`: Test result snapshots
- `tests/`: GraphQL test queries

## Key Commands

### Compilation
```bash
# Compile a SQRL script
docker run --rm -v $PWD:/build datasqrl/cmd compile script.sqrl

# Compile with configuration file
docker run --rm -v $PWD:/build datasqrl/cmd compile -c package.json

# Generate GraphQL API schema
docker run --rm -v $PWD:/build datasqrl/cmd compile script.sqrl --api graphql
```

### Running & Testing
```bash
# Run a data pipeline locally
docker run -it -p 8888:8888 -p 8081:8081 -p 9092:9092 --rm -v $PWD:/build datasqrl/cmd run -c package.json

# Run tests
docker run --rm -v $PWD:/build datasqrl/cmd test -c package.json
```

As for compile, you can also provide a .sqrl script as argument instead of a package.json file.

## SQRL Language Features

- **Table definitions**: `TableName := SELECT ...`
- **Functions**: `FuncName(arg TYPE) := SELECT ... WHERE col = :arg`
- **Relationships**: `Parent.relation := SELECT ... WHERE this.id = child.parent_id`
- **Subscriptions**: `AlertTable := SUBSCRIBE SELECT ...`
- **External connectors**: `CREATE TABLE ... WITH ('connector'='kafka', ...)`
- **API Mutation endpoint**: `CREATE TABLE ... (..., event_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp')`
- **Hints**: `/*+primary_key(col), index(HASH, col2)*/`

## Common Patterns

### Import Sources
```sql
IMPORT kafka-source.MyTable;
IMPORT testdata.*;  -- Import all from testdata folder
```

### Stream Processing
```sql
-- Deduplicate changelog data
CleanData := DISTINCT RawData ON id ORDER BY updated DESC;

-- Temporal joins for enrichment
Enriched := SELECT s.*, d.info 
           FROM Stream s 
           JOIN Dimension FOR SYSTEM_TIME AS OF s.event_time d 
           ON s.key = d.key;
```

### API Exposure
```sql
-- Query endpoint with required filter
/*+query_by_all(userid)*/
UserStats := SELECT userid, count(*) FROM Events GROUP BY userid;

-- Subscription endpoint
Alerts := SUBSCRIBE SELECT * FROM Events WHERE severity = 'HIGH';
```

## Testing

Mark test cases with `/*+test */` hint or place GraphQL queries in `tests/` directory:

```sql
/*+test */
TestResults := SELECT * FROM MyTable ORDER BY id;
```

## Configuration

Each project uses `package.json` files to configure:
- Enabled engines: `["vertx", "postgres", "kafka", "flink"]`
- Engine-specific settings
- Connector templates
- Dependencies for different environments

## Getting Help

- Use the `--help` flag with any command
- Check project-specific README files
- Reference the full [DataSQRL documentation](datasqrl_documentation.md) for detailed specifications of the SQRL language, configuration, or additional information.

## Memories
- Always read the full [DataSQRL documentation](datasqrl_documentation.md) into cache first.
- The datatype for METADATA FROM 'uuid' columns must always be STRING
- Don't add `query_by_*` hints on table functions - those already define a query endpoint.
- Before creating a new project, look at similar projects to mirror their structure.