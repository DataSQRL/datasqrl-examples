# Healthcare Study Analytics Example

This script produces study analytics for observations groups in Iceberg tables that are queried by DuckDB.

Run the `study_analytics.sqrl` script using iceberg and duckdb locally as follows:
```bash
docker run -it -p 8888:8888 -p 8081:8081 --rm -v $PWD:/build datasqrl/cmd:latest run -c study_analytics_package_test.json
```

This writes the data to the local directory `warehouse` which is configured in `study_analytics_package_test.json`
under the `warehouse` configuration option. Delete that directory if you re-run the example or make changes to it,
otherwise you might run into errors of catalog mismatch.

There is also a package configuration for running this example using Snowflake as the query engine.
