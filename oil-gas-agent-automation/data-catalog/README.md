# Data Catalog for the Oil & Gas Automated Monitoring Example

Shared by the monitoring and operations projects. Four datasets:

| Table | Grain | Description |
|-------|-------|-------------|
| `Assets` | one row per `asset_id` and `lastUpdated` | The wells: number, name, category, cost, status, manual link |
| `Maintenance` | one row per `work_order_id` and `lastUpdated` | Maintenance work orders on a well: type, priority, status, request/start/completion dates |
| `FlowRate` | one row per `assetId` and `event_time` | Flow-rate readings from the wells |
| `Measurement` | one row per `assetId` and `timestamp` | Pressure (psi) and temperature (°F) readings from the wells |

| File | Purpose |
|------|---------|
| `sources.sqrl` | The column definitions of the four tables (`_X_schema`), written once and documented; the environment files extend them with `LIKE _X_schema` |
| `sources-test.sqrl` | All four tables as file sources (`LIKE testdata/*.jsonl[.gz]`) — the `test` environment |
| `sources-dev.sqrl` | The same tables as Kafka topics `assets`, `maintenance`, `flowrate`, `measurement`, columns from `sources.sqrl` — the `dev` environment |
| `ontology.sqrl` | Relationships (well ↔ work orders, well ↔ readings) and the data quality assertions that must never be violated; run with `ontology-shared-package.json` + `ontology-test-package.json` |

Projects import the catalog as `` `data-catalog`.`sources-{{environment}}` `` and select the environment in their package configuration.
