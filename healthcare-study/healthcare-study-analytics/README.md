# Healthcare Study Analytics Example

This script produces study analytics for observations groups in Iceberg tables that are queried by DuckDB.

Run the `study_analytics.sqrl` script using iceberg and duckdb locally as follows (from the `healthcare-study`
directory, so the shared `data-catalog` is mounted too):
```bash
docker run -it -p 8888:8888 -p 8081:8081 --rm -v $PWD:/workspace datasqrl/cmd:latest run \
  -r healthcare-study-analytics \
  study_analytics-shared-package.json \
  study_analytics-test-package.json
```

To run the tests, use `./run-tests.sh` inside this directory.

This writes the data to the local directory `warehouse` which is configured in `study_analytics-test-package.json`
under the `warehouse` configuration option. Delete that directory if you re-run the example or make changes to it,
otherwise you might run into errors of catalog mismatch.

## Snowflake as Query Engine

The `prod` overlay runs this example with Kafka sources, Iceberg on S3 and Snowflake as the query engine:
```bash
docker run -it -p 8888:8888 -p 8081:8081 --rm \
  -v $PWD:/workspace \
  -e AWS_ACCESS_KEY_ID="<my-access-key>" \
  -e AWS_SECRET_ACCESS_KEY="<my-secret-key" \
  -e AWS_REGION="<my-region>" \
  -e SNOWFLAKE_JDBC_URL="<my-snowflake-jdbc-url>" \
  datasqrl/cmd:latest run \
  -r healthcare-study-analytics \
  study_analytics-shared-package.json \
  study_analytics-prod-package.json
```

> [!IMPORTANT]
> Make sure you pass the `SNOWFLAKE_JDBC_URL` environment variable to the container, that should be set to the complete JDBC URL.
> For example: `jdbc:snowflake://abc12345.eu-central-1.snowflakecomputing.com/?user=MYUSER&password=MYPASSWORDwarehouse=MYWH&db=MYDB&schema=MYSCHEMA&role=MYROLE`

> [!IMPORTANT]
> You must set a proper AWS access key, and a valid S3 bucket as `warehouse` in [study_analytics-prod-package.json](study_analytics-prod-package.json),
> or create the `my-iceberg-warehouse` bucket in the given AWS account.
