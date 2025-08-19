# Healthcare Study Analytics Example

This script produces study analytics for observations groups in Iceberg tables that are queried by DuckDB.

Run the `study_analytics.sqrl` script using iceberg and duckdb locally as follows:
```bash
docker run -it -p 8888:8888 -p 8081:8081 --rm -v $PWD:/build datasqrl/cmd:latest run -c study_analytics_package_test.json
```

This writes the data to the local directory `warehouse` which is configured in `study_analytics_package_test.json`
under the `warehouse` configuration option. Delete that directory if you re-run the example or make changes to it,
otherwise you might run into errors of catalog mismatch.

## Snowflake as Query Engine

There is also a package configuration for running this example using Snowflake as the query engine:
```bash
docker run -it -p 8888:8888 -p 8081:8081 --rm \
  -v $PWD:/build \
  -e AWS_ACCESS_KEY_ID="<my-access-key>" \
  -e AWS_SECRET_ACCESS_KEY="<my-secret-key" \
  -e AWS_REGION="<my-region>" \
  -e SNOWFLAKE_JDBC_URL="<my-snowflake-jdbc-url>" \
  datasqrl/cmd:latest run -c study_analytics_package_snowflake.json
```

> [!IMPORTANT]
> Make sure you pass the `SNOWFLAKE_JDBC_URL` environment variable to the container, that should be set to the complete JDBC URL.
> For example: `jdbc:snowflake://abc12345.eu-central-1.snowflakecomputing.com/?user=MYUSER&password=MYPASSWORDwarehouse=MYWH&db=MYDB&schema=MYSCHEMA&role=MYROLE`

> [!IMPORTANT]
> You must set a proper AWS access key, and a valid S3 bucket as `warehouse` in [study_analytics_package_snowflake.json](study_analytics_package_snowflake.json),
> or create the `my-iceberg-warehouse` bucket in the given AWS account.
