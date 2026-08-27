# Automated Monitoring - Oil & Gas Use Case

Two projects over one shared [`data-catalog`](data-catalog) of wells (`Assets`), their maintenance work
orders and their flow-rate and pressure/temperature readings:

* [**oil-gas-agent-monitoring**](oil-gas-agent-monitoring): a query API for an agent — well profiles with
  their work orders and per-minute flow-rate and pressure aggregates (environments: `test`, `dev`).
* [**oil-gas-agent-operations**](oil-gas-agent-operations): the same well data plus an **ingest mutation**
  for flow-rate readings, a `LowFlowRate` subscription that pushes enriched readings below 200, and recent
  pressure/temperature per well (environments: `test`, `dev`).

Each project keeps its configuration in a base manifest (`<script>-shared-package.json`) plus thin
per-environment overlays: `test` reads the sample files bundled in the catalog (`sources-test.sqrl`), `dev`
reads Kafka topics (`sources-dev.sqrl`; the dev overlays list those topics under `test-runner.create-topics`,
so a local run starts its own Redpanda and creates them). DataSQRL merges the manifests in the order given —
later files override earlier ones. Because the projects import the catalog next to them, the commands mount
this directory at `/workspace` and name the project with `-r`.

Every project ships `run-tests.sh`, the single entry point for its test suites: `./run-tests.sh` runs every
suite, `./run-tests.sh --compile --env dev` compiles the dev configuration, and
`./run-tests.sh --list-invocations` prints what would run without running it.

## Run the operations backend

```bash
cd oil-gas-agent-automation
docker run -it -p 8888:8888 -p 8081:8081 -p 9092:9092 --rm -v $PWD:/workspace datasqrl/cmd:latest run \
  -r oil-gas-agent-operations \
  operations_agent-shared-package.json \
  operations_agent-test-package.json
```

To publish flowrate metrics, open [GraphiQL in the browser](http://localhost:8888/v1/graphiql/) and run the following mutation:

```graphql
mutation {
  AddFlowRate(event: {assetId: 12221, flowrate: 220.5 }) {
    assetId
    flowrate
  }
}
```

This sample dataset has 5 pre-defined wells (i.e. assets) with the following ids:
`12221, 21112, 34443, 45555, 59995`

Open GraphiQL again in another window and listen to this subscription:
```graphql
subscription {
  LowFlowRate {
    assetId
    flowrate
  }
}
```

Add another flowrate metric with a value below `200` and observe it through the subscription.
To retrieve recent pressure and temperature readings for a well, run this query:
```graphql
{
  RecentPressure(assetId: 12221) {
    pressure_psi
    temperature_f
    timestamp_normalized
  }
}
```

The monitoring backend runs the same way with `-r oil-gas-agent-monitoring` and the
`monitoring_agent-*-package.json` manifests.
