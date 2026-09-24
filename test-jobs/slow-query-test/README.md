# Slow GraphQL Query Alert Test

Deployment test job for the per-query slow-query alerts in cloud-backend
(`metrics/metrics_alerting.sqrl` → `_SlowQueryAlerts`).

## How the alert pipeline works

1. The vertx server times every generated GraphQL query and publishes the
   micrometer summary `sqrl_graphql_query_duration_seconds` tagged with
   `name=<GraphQL field name>` and quantiles 0.5/0.99
   (`GraphQLQueryMetricsInstrumentation`).
2. Prometheus recording rules in `customer-dataplane-infrastructure`
   (`sqrlpipeline-observability/.../vertx.yaml.tftpl`) derive
   `x_sqrl_graphql_query_p50_seconds` / `x_sqrl_graphql_query_p99_seconds`
   per `(deploymentId, service, name)` using `max_over_time(...[5m:])`.
3. The cloud-backend metrics pipeline ingests these as
   `BackendDeploymentMetrics` (the `name` label becomes `taskName`) and raises
   an alert named `slow-query:<queryName>` when **p99 > 20s (level 1)** or
   **p99 > 50s (level 2)** (thresholds in
   `metrics/data-sources/static-data/metric_alerts_config.jsonl`).

This job exposes two query endpoints:

- `SlowQuery(n)` — cross-joins a 100k-row Postgres table with itself,
  restricted to `id <= n` on both sides. Latency grows quadratically with `n`,
  so you can dial p99 past either threshold at query time without redeploying.
- `FastQuery(maxId)` — control; must never raise a slow-query alert.

## Runbook

### 1. Deploy

Deploy this package (`slow-query-package.json`) to the target environment
(e.g. staging). Wait for the Flink job to finish seeding (~10s of datagen at
10k rows/sec; the 1 row/sec heartbeat source keeps the job running afterwards).

### 2. Calibrate latency

```bash
ENDPOINT=https://<deployment-graphql-endpoint>/graphql

time curl -s "$ENDPOINT" -H 'Content-Type: application/json' \
  -d '{"query":"query { SlowQuery(n: 20000) { row_pairs max_id_sum } }"}'
```

Latency scales with `n²`: if `n=20000` takes `t` seconds, `n=20000*sqrt(k)`
takes roughly `k*t`. Pick an `n` that lands in **25–40s** to trigger level 1,
or **>50s** for level 2 (only reachable if no server/Postgres statement
timeout cuts the request short — a timeout still records its duration in the
timer, so a ~30s timeout caps observable p99 around 30s).

### 3. Trigger the alert

Fire a handful of slow queries so the p99 summary quantile reflects them
(micrometer decays samples after a few minutes, so keep a slow trickle going):

```bash
for i in $(seq 1 10); do
  curl -s "$ENDPOINT" -H 'Content-Type: application/json' \
    -d '{"query":"query { SlowQuery(n: <calibrated>) { row_pairs max_id_sum } }"}' > /dev/null
done
```

Also run the control a few times:

```bash
curl -s "$ENDPOINT" -H 'Content-Type: application/json' \
  -d '{"query":"query { FastQuery(maxId: 100) { id payload } }"}'
```

### 4. Verify

Allow ~5–10 min end to end (Prometheus scrape + `[5m:]` recording-rule window
+ metrics-pipeline ingestion). Then check the environment's alerts (UI alert
panel or the metrics `getAlerts` GraphQL query) for the deployment:

- `slow-query:SlowQuery` present — level 1 with trigger
  `p99 latency <x>s exceeds threshold 20.0s`, or level 2 against 50s.
- No `slow-query:FastQuery` alert.
- Distinct slow queries alert independently (alert identity is
  `slow-query:<name>`), so hitting both `SlowQuery` and another expensive query
  yields separate alerts that snooze independently.

Note: because the recording rule uses `max_over_time(...[5m:])`, the alert
condition persists ~5 min after the last slow query.

### 5. Clean up

Delete the deployment. Logic-level coverage (no cluster needed) already exists
in cloud-backend: `metrics` snapshot test `SlowQueryAlertTest` plus the
`x_sqrl_graphql_query_*` rows in
`metrics/cluster-events-local/BackendDeploymentMetrics.jsonl`.
