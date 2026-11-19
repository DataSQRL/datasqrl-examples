# Usage Analytics

- **Builds:** a data API that tracks LLM token usage per user, serves hourly totals, and alerts when a user goes over the limit.
- **Shows:** data API
- **Built with:** SQRL compiled to Flink, Kafka, Postgres, and the DataSQRL API server.

Every request a user makes records the number of tokens it used. The pipeline sums each user's tokens in a cumulating one-hour window that updates every 10 seconds, serves the latest total per user and hour, and pushes an alert when a user's hourly total goes above 1,000,000 tokens.

The script is [`usertokens.sqrl`](usertokens.sqrl). It takes its source from one of two variants:

| Package file | Source |
| --- | --- |
| `usertokens_api_package.json` | [`usertokens-api`](usertokens-api): a `UserTokens` mutation in the API, backed by Kafka |
| `usertokens_test_package.json` | [`usertokens-testdata`](usertokens-testdata): sample records in `user_tokens.jsonl` |

The API has:

- the `UserTokens` mutation, to record a request's token count (API variant only),
- the `UserTokenUsageHourly` query, the hourly totals by user,
- the `UsageAlert` subscription, users over the hourly limit.

## Run the tests

```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest test usertokens_test_package.json
```

The test compares the `UserTokenTest` query to the snapshot in [`snapshots`](snapshots).

## Run the API

```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest run usertokens_api_package.json
```

Open [GraphiQL](http://localhost:8888/v1/graphiql/), subscribe to `UsageAlert` in one window, and record usage in another:

```graphql
mutation {
  UserTokens(event: {userid: 1, tokens: 600000}) {
    userid
  }
}
```

Run the mutation twice for the same user to go over the limit and see the alert.

## Build this with the DataSQRL plugin

Install the [DataSQRL plugin](https://github.com/DataSQRL/datasqrl-plugin) in Claude Code, Codex, Cursor, or Copilot, then paste this prompt:

```text
Build a DataSQRL data API for LLM token usage. Add a GraphQL mutation that records a user id and
the tokens a request used, serve each user's token total per hour, updated every 10 seconds, and
push a subscription alert when a user goes over 1,000,000 tokens in an hour.
```
