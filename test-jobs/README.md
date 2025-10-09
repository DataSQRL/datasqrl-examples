# Test Jobs

This folder contains simple DataSQRL test jobs to evaluate operations without external dependencies.

Unlike the other projects in this repository, these jobs are not real use cases but meant solely for
testing.

* [Aggregation](aggregation-test.sqrl): Tests Flink with logging using generated data
* [Aggregation Query](aggregation-query-test.sqrl): Tests Flink -> Postgres -> Vertx using generated data
* [Aggregation Query Subscription](aggregation-query-subscription-test.sqrl): Tests Flink -> Postgres + Kafka -> Vertx using generated data