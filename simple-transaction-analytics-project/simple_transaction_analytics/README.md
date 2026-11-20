# Spending Insights

A nightly batch DataSQRL pipeline that reads the shared retail-bank **data catalog**
(`data-catalog`, mounted read-only beside this project) and computes per-customer spending
insights over a bounded 7-day window. The results are written to Apache Iceberg and served
through a JWT-authenticated GraphQL / REST / MCP API backed by DuckDB + Vert.x.

## Motivation

A bank's service agents need a single view of *how a customer is spending* — category
breakdowns, top merchants, recurring-payment cost, unusually large purchases and month-over-month
cash flow. The catalog already provides the conformed inputs (enriched transactions, categories,
merchant enrichment, recurring-payment detection, reversals, accounts, customers). This pipeline
turns those inputs into **insights** and owns exactly one new source of its own, `Fx_Daily_Rate`
(a daily currency-to-USD rate table the catalog does not provide).

## Architecture

The pipeline is a **batch Flink job** (`execution.runtime-mode = BATCH`) that runs once per night
and is fully deterministic: every date derives from a single `run_date` (operator-overridable in
production, defaulting to `CURRENT_DATE - 1` UTC), so re-running the same `run_date` over the same
input reproduces the same output.

The core computation:

1. **Read & dedup.** Four bronze catalog sources (`Customer`, `Account`, `Account_Holder`,
   `Transaction_Reversal`) are Kafka CDC streams and are collapsed to their latest snapshot with
   `DISTINCT ... ORDER BY source_updated_at DESC`. The four enriched sources
   (`Unified_Transaction`, `Merchant_Enrichment`, `Transaction_Category`, `Recurring_Payment`) are
   Iceberg upsert tables and are read as-is.
2. **Run control.** `run_date` → `window_start = run_date - 6 days`, `window_end = run_date`,
   `read_from = (month of window_start) - 3 months`, and the partial-month marker.
3. **Classify.** Restrict to `CHECKING`/`SAVINGS` accounts; spending = `POSTED`+`DEBIT`, income =
   `POSTED`+`CREDIT`; exclude internal transfers (marked category/type *and* a deterministic
   same-customer pairing rule); net `PARTIAL`/`CORRECTION` reversals against the still-`POSTED`
   original at the original's business date.
4. **Convert to USD** via `Fx_Daily_Rate` at the transaction's `posted_date`, carrying forward the
   most recent earlier rate (USD = 1.0; a currency with no rate and no earlier rate is excluded and
   counted).
5. **Resolve** each transaction's level-1 and level-2 category (`Uncategorized` when absent) and
   merchant (`Unknown merchant` when absent).
6. **Aggregate** the 13 output tables (category spending with a 3-month normal-spending baseline and
   a "much more than usual" flag, top-5 merchants, recurring-payment cost and price-increase flag,
   large purchases with a 90-day baseline, cash flow and daily spending) and two monitoring tables.

### Outputs (Iceberg, database `insights`, Hadoop catalog `spending_insights`)

| Table | Key |
|---|---|
| `Customer_Month_Category_L1_Spending` | `(customer_id, month, category_l1_id)` |
| `Customer_Month_Category_L2_Spending` | `(customer_id, month, category_l2_id)` |
| `Customer_Month_Top_Merchant` | `(customer_id, month, merchant_rank)` |
| `Customer_Month_Category_Merchant` | `(customer_id, month, category_l2_id, merchant_id)` |
| `Customer_Recurring_Payment` | `(customer_id, recurring_payment_id)` |
| `Customer_Recurring_Monthly_Total` | `(customer_id)` |
| `Customer_Large_Purchase` | `(transaction_id)` |
| `Customer_Month_Cash_Flow` | `(customer_id, month)` |
| `Customer_Account_Month_Cash_Flow` | `(customer_id, account_id, month)` |
| `Customer_Day_Spending` | `(customer_id, spend_date)` |
| `Customer_Account_Day_Spending` | `(customer_id, account_id, spend_date)` |
| `Pipeline_Run_Metric` | `(run_date)` |
| `Uncategorized_Spending_Daily` | `(spend_date)` |

Every output is an Iceberg sink with `PRIMARY KEY NOT ENFORCED` and `write.upsert.enabled = true`,
so month-grain outputs rewrite only the touched months and transaction-grain outputs rewrite only
the window days (incrementality), while every other key stays byte-identical to the previous run.

### API

`endpoints: OPS_ONLY`; 12 named operations (no mutations/subscriptions), all requiring a valid JWT
(HS256, issuer `spending-insights`, audience `spending-console`). Any signed-in staff user may read
any customer. Operations: `CustomerSearch`, `CustomerAccounts`, `MonthOverview`, `DailySpending`,
`CategorySpending`, `CategoryMerchants`, `TopMerchants`, `RecurringPayments`, `RecurringTotal`,
`LargePurchases`, `RunMetrics`, `UncategorizedShare`.

## Engines

`flink` (batch), `iceberg` (lake format), `duckdb` (query engine + tests + API serving), `vertx`
(API). No `postgres` (no DB-backed serving tables) and no `kafka` (no subscriptions/mutations).

## Layout

```
spending_insights.sqrl                     # pipeline + API functions + tests
spending_insights-shared-package.json      # base config (shared by both sub-projects)
spending_insights-test-package.json        # run_date 2026-09-02, snapshots/spending_insights/
spending_insights-replay-test-package.json # run_date 2026-09-05, snapshots/spending_insights_replay/
spending_insights-prod-package.json        # production (run_date defaults to yesterday UTC)
connectors/fx_rates{-test,-prod}.sqrl      # project-owned Fx_Daily_Rate source
connectors/insights_sinks{-test,-prod}.sqrl # Iceberg sinks for the output tables
spending_insights-api/                     # GraphQL schema + operations + tests
testdata/fx_daily_rate.jsonl               # FX test data (EUR carry-forward, JPY missing-rate)
run-tests.sh                               # test runner (both sub-projects)
```

## Run locally with the UI

Start Docker Desktop, then run the pipeline/API and UI in **two separate terminals**.
You also need Node.js/npm for the UI and Python 3 for the test-token command below.
These commands use this checkout's paths and the bundled test data.

### Terminal 1 — pipeline + API

Mount the parent `simple-transaction-analytics-project` directory so the pipeline can
access its sibling `data-catalog` through `../data-catalog`:

```bash
cd /Users/hasanalpcaferoglu/3.company_projects/data_sqlr_all/codes/datasqrl-examples/simple-transaction-analytics-project

docker run --rm -it \
  -p 8888:8888 -p 8081:8081 \
  -v "$PWD:/workspace" \
  datasqrl/cmd:0.11.5 \
  run -r simple_transaction_analytics \
  spending_insights-shared-package.json \
  spending_insights-test-package.json \
  -b spending_insights
```

The GraphQL API is available at `http://localhost:8888/v1/graphql` once startup completes.
If `datasqrl/cmd:0.11.5` is unavailable, replace it with `datasqrl/cmd:dev` in the command
above. This is the fallback image configured in `run-tests.sh`; the direct Docker command
does not switch images automatically.

### Terminal 2 — UI

```bash
cd /Users/hasanalpcaferoglu/3.company_projects/data_sqlr_all/codes/datasqrl-examples/simple-transaction-analytics-project/simple_transaction_analytics/ui

npm install
VITE_API_URL=http://localhost:8888/v1/graphql npm run dev
```

Open [http://localhost:5173](http://localhost:5173). If that port is already in use,
open the local URL printed by Vite instead.

### Sign in with the bundled test JWT

In another terminal, copy the bundled test token to your macOS clipboard:

```bash
cd /Users/hasanalpcaferoglu/3.company_projects/data_sqlr_all/codes/datasqrl-examples/simple-transaction-analytics-project/simple_transaction_analytics

python3 -c 'import json; print(json.load(open("spending_insights-test-package.json"))["test-runner"]["headers"]["Authorization"].removeprefix("Bearer "))' | pbcopy
```

Paste the token into the UI's sign-in field. The command removes the `Bearer ` prefix;
the UI adds it when sending API requests. This token is for the bundled test configuration.

Keep both services running while using the UI. Press `Ctrl+C` in each service terminal
to stop it.

## Compile, test, run

The project is a subdirectory of the repository mounted at `/workspace`; the shared `data-catalog`
module sits beside it. Config paths are resolved at the mount root, so commands are project-qualified.

```bash
# compile (base + test overlay)
/opt/agent/cmd.sh compile -r simple_transaction_analytics \
  spending_insights-shared-package.json spending_insights-test-package.json -b spending_insights

# test both sub-projects (run_date 2026-09-02 and 2026-09-05)
./run-tests.sh
```

## Data quality and observability

This project adds three runtime tables; it **reuses** (does not rebuild) the catalog's build-time
`/*+test(no_rows) */` referential-integrity and enum-validity assertions over the same source data.

- **`Pipeline_Run_Metric`** (observability, keyed `run_date`) — one row per run: `run_date`,
  `window_start`, `window_end`, `recomputed_day_count`, `recomputed_months`,
  `transaction_count_processed`, `late_transaction_count`, `missing_fx_rate_txn_count`. The single
  source of truth for "is the 7-day window long enough" (a consistently non-zero
  `late_transaction_count` is the agreed signal to widen the window).
- **`Uncategorized_Spending_Daily`** (observability, keyed `spend_date`) — one row per window day:
  total spending, uncategorized spending, uncategorized share, and transaction counts. A break in the
  transactions team's categorization shows up here the next morning.
- **`DQ_Missing_FX_Rate_Transaction`** (data quality, keyed `transaction_id`) — one row per
  transaction dropped from every insight because its currency has no rate and no earlier rate; the
  row-level capture behind `missing_fx_rate_txn_count`.

Reused catalog assertions: `deposits_payments/deposits_payments-ontology.sqrl` and `ontology.sqrl`
(see the catalog) assert referential integrity and enum validity for the same source tables at build
time.

## Note on the batch scheduler

Flink 2.x's default batch scheduler (`AdaptiveBatch`) performs a runtime *adaptive join*
optimization whose planner/runtime classes are loaded by different classloaders in DataSQRL 0.11.x,
crashing the job with a `ClassCastException`. The pipeline therefore pins the classic batch
scheduler via `jobmanager.scheduler = Default` (in `engines.flink.config`), which avoids the
adaptive join and lets the batch job run cleanly.
