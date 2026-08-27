# Finance Credit Card ChatBot Examples

This project contains three example use cases that process credit card transaction, customer, and merchant data:

* [**Transaction Analytics**](credit-card-analytics): A data pipeline which enriches the credit card
  transactions with customer and merchant information to give customers an overview of their transactions as well as
  some analytics on their spending.
  * To run this data pipeline with file data, add the `creditcard_analytics-test-package.json` manifest file.
  * To run this data pipeline with Kafka as the data source, add the `creditcard_analytics-dev-package.json` manifest file.
* [**Credit Card Rewards**](credit-card-rewards): A data pipeline that implements a credit card rewards program.
  Merchants sign up for cash-back rewards on certain credit card types during certain periods and customer get a cash
  reward when they make a purchase at the merchant during that time. The data pipeline processes the rewards and give
  the customer insight into the reward they earned.
  * To run this data pipeline with file data, add the `creditcard_rewards-test-package.json` manifest file.
  * To run this data pipeline with Kafka as the data source, add the `creditcard_rewards-dev-package.json` manifest file.
* [**Spending Views**](credit-card-views): A batch-oriented variant of the transaction analytics that writes the
  spending aggregates to Iceberg tables — queried locally through DuckDB, and in production through Snowflake.
  * To run it with file data, add the `creditcard_views-test-package.json` manifest file.
  * The `creditcard_views-prod-package.json` manifest switches to Kafka sources, Iceberg on S3/Glue and Snowflake
    (it expects `SNOWFLAKE_JDBC_URL` in the environment).

Each use case keeps its configuration in a **base manifest** plus thin overlays:

| Manifest | Role |
|----------|------|
| `<script>-shared-package.json` | base — engines, main script, the `data-catalog` include: everything every environment has in common |
| `<script>-test-package.json` | test environment — file data sources, snapshot tests; for the two API use cases also the JWT configuration, so the test suite covers authentication |
| `<script>-dev-package.json` | local development environment — Kafka data sources (*Transaction Analytics*, *Credit Card Rewards*) |
| `<script>-prod-package.json` | production environment — Kafka sources, Iceberg on S3, Snowflake (*Spending Views*) |

DataSQRL merges the manifests in the order they are given — later files override earlier ones, objects
are deep-merged and arrays are replaced — so every command below passes the base first and the
overlay second.

Every use case imports the shared [`data-catalog`](data-catalog) that sits next to it (`script.include`
in the base manifest, path `../data-catalog/package.json`). The commands below therefore mount this
directory — not the project — at `/workspace`, and `-r <project>` tells the compiler which project to build.

Each use case also ships a `run-tests.sh` at its root, the single entry point for its test suites:
`./run-tests.sh` runs every suite, `./run-tests.sh --compile --env dev` compiles the dev configuration, and
`./run-tests.sh --list-invocations` prints what would run without running it.

See below for detailed instructions on how to run each data pipeline.
Note, that the instructions are for the *Transaction Analytics* use case.
Replace the manifest files to run the *Credit Card Rewards* use case (i.e. `rewards` instead of `analytics` in the
package JSON filename, and `-r credit-card-rewards`) - the instructions are otherwise identical.

## 1. Run the API with File data source

To run this example, invoke the following command in the example directory on Unix based systems to compile the project:
```bash
cd finance-credit-card-chatbot
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/workspace datasqrl/cmd:latest run \
  -r credit-card-analytics \
  creditcard_analytics-shared-package.json \
  creditcard_analytics-test-package.json
```

This command stands up the API using [DataSQRL](https://www.datasqrl.com/), a development tool
for data pipelines. To check that the GraphQL API is running properly, [open GraphiQL](http://localhost:8888/v1/graphiql/) to access the API.

The test environments of *Transaction Analytics* and *Credit Card Rewards* secure the API with JWT (see
[Securing the API endpoints](#3-securing-the-api-endpoints)), so every request — including the ones you
send from GraphiQL — needs an `Authorization` header. Use the token from the use case's
`*-test-package.json` (`test-runner.headers`); for *Transaction Analytics*, open the *Headers* pane in GraphiQL and add
```json
{ "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkdW1teS1pc3N1ZXIiLCJhdWQiOlsiZHVtbXktYXVkaWVuY2UiXSwiZXhwIjo5OTk5OTk5OTk5fQ.3WQJxy-RsmvHskT4dvQp2ti-E88me5y-kkquy0SJ3SA" }
```

When you are done, you can stop the pipeline by hitting CTRL-C.

## 2. Run the API with Kafka data source

The instructions above run the data pipeline with data ingested from local files. While this is great for testing and local development,
most production use cases need to ingest data from an external data source like Kafka.

To use Kafka as the data source, follow these steps:

Invoke the following command in the example directory:
```bash
cd finance-credit-card-chatbot
docker run -it -p 8081:8081 -p 8888:8888 -p 9092:9092 --rm -v $PWD:/workspace datasqrl/cmd:latest run \
  -r credit-card-analytics \
  creditcard_analytics-shared-package.json \
  creditcard_analytics-dev-package.json
```

This command stands up the entire data pipeline and all data services, including Kafka.

Now, we need to write the data to Kafka, so it can be consumed by the pipeline.

The easiest way to do so is to use a little helper python script
that reads the data from a file and writes it to the kafka topic. This requires you have Python3 installed on your machine.

From this directory (`finance-credit-card-chatbot`), invoke the script four times in the following order to
populate Kafka — the data files live in the shared `data-catalog`:
1. `python3 ../util/load_data.py data-catalog/testdata/merchant.jsonl localhost:9092 merchant --msg 500`
2. `python3 ../util/load_data.py data-catalog/testdata/merchant_reward.jsonl localhost:9092 merchantreward --msg 500`
3. `python3 ../util/load_data.py data-catalog/testdata/card_assignment.jsonl localhost:9092 cardassignment --msg 500`
4. `python3 ../util/load_data.py data-catalog/testdata/transaction.jsonl localhost:9092 transaction --msg 50`

The first load should be pretty quick. The transactions are then loaded at a rate of 50 per second (You can adjust the rate via the `--msg` option).

To see how the data enters the topics and the [Flink UI](http://localhost:8081/) to see the processing status.

As above, you can [open GraphiQL](http://localhost:8888/v1/graphiql/) to access the API and query for data. Note, that the time windows are very long,
so you won't be seeing any output there for the short period of time we are inserting data.
You can adjust the time windows or keep loading data for a long time ;-).

When you are done, you can stop the pipeline by hitting CTRL-C.

## 3. Securing the API endpoints

Both API use cases secure their public endpoints with JWT (HS256, signed with a dummy key — replace it before any
real deployment). The `engines.vertx` block with `authKind: ["JWT"]` is where that is configured.

Both carry the JWT configuration in their **test overlay**, so the file-data command in section 1
already starts a secured API, and each test suite sends the valid token from `test-runner.headers` with every
query. A `.properties` file next to a test query overrides the headers for that one query:

* *Transaction Analytics* ships a negative test, `creditcard_analytics-api/tests/invalid-token.graphql`: its
  `invalid-token.properties` sends an invalid token, and its snapshot records the rejection.
* *Credit Card Rewards* reads the caller's identity from the token — its endpoints declare
  `customerId BIGINT NOT NULL METADATA FROM 'auth.customerId'`, so the `customerId` claim selects whose rewards
  are returned. The default token carries `customerId: 9`; `creditcard_rewards-api/tests/test-customerId-2.properties`
  sends a token for customer 2 to show the same query answering for another customer.

It is also possible to construct additional API tests and operations via the DataSQRL test runner.
Take a look at the [Transaction Analytics](credit-card-analytics) example to see how those can be set up.

## 4. Run the MCP Inspector

Both use cases can utilize the MCP inspector. If API is running, open a new terminal and invoke the following command:
```bash
npx @modelcontextprotocol/inspector
```
Assuming `npm` is installed, first time, this will install a new `npm` package, then it will start the inspector.
In the browser window that pop up, pick **Streamable HTTP**, and the SQRL MCP server should be available at `http://localhost:8888/v1/mcp`.

All public API endpoints will be listed under. **Tools**. For more information about MCP inspector, [see its documentation](https://modelcontextprotocol.io/docs/tools/inspector). 
