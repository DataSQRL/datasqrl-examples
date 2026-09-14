# Distressed Loan Dashboard

A nightly batch pipeline that reconciles loan-payment and delinquency-event sources (auto loans, personal loans, mortgages, and credit cards) into exactly-once "payment obligation" records, then computes weekly distress aggregations keyed by **(week, zip code)** and **(week, customer)**. The result is served through a **GraphQL + MCP** API over Postgres for an internal dashboard: a per-zip geographic overview with a two-week trend, a 12-week zip drill-down chart, and a per-zip table of distressed customers.

## Motivation

A bank wants to see, week over week, where its lending portfolio is under stress — which zip codes and which customers have the most payments that are late or not made at all. The requirements (R1–R17) specify:

- Per week and per zip code (R1) and per customer (R2): count and amount of payments due, posted on time, posted late, not posted, and distressed, plus percent distressed and average days late.
- A nightly batch job (R3) that recomputes the last three months and replaces prior results (R4).
- Zip codes assigned at computation time, so a customer who moves is attributed to their new zip for the whole window (R5); the late/not-posted split can change between runs while the distressed total stays stable (R6).
- A dashboard (R7–R14) and an API (R15–R17) that supports everything the dashboard does, including zip-prefix and state filtering.

The full requirements are in `adr/requirements_20260911-205513.md`; the implementation plan is in `adr/plan_20260914-181127.md`.

## Architecture

```
sources (filesystem test / Kafka prod)
   └─ normalize → reconcile → classify (Flink batch)
        ├─ _PaymentObligations   (posted payments: on-time / late)
        └─ _DelinquencyObligations (missed-payment events: not-posted)
        └─ exactly-once dedup on (account_id, due_date): a posted payment
           supersedes a matching delinquency event (→ posted late)
   └─ aggregate by week_due (buckets) + week_posted (avg days late)
   └─ ZipWeeklyAgg / CustomerWeeklyAgg → Postgres (materialized)
   └─ ZipOverview / ZipHistory / ZipDistressSummary / DistressedCustomers
   └─ GraphQL + MCP (Vert.x)
```

- **Flink** (batch, `execution.runtime-mode: BATCH`) reads the bounded snapshot and fully recomputes. The week computation (`FLOOR(<date> TO WEEK)`, Sunday-start) is pinned to Flink so it does not leak Flink-only syntax into Postgres.
- **Postgres** serves the materialized aggregate tables.
- **Vert.x** exposes GraphQL and MCP. No `kafka` (read-only, no mutations/subscriptions) and no `iceberg` (no data-lake sink).

The source tables are reused from the shared `data-catalog` module via `script.include` (namespaced `_schema` import + `LIKE`), with this project's own connectors (`connectors/sources-test.sqrl` filesystem, `connectors/sources-prod.sqrl` bounded Kafka) so the acceptance criteria can be exercised against controlled test data.

## Reconciliation model

Every payment due in a week is exactly one of:

- **posted on time** — posted by its due date.
- **posted late** — posted after its due date (includes delinquent payments paid later).
- **not posted** — no payment, recorded as a `MISSED_PAYMENT` delinquency event.

Derived: `payments due = on-time + late + not-posted`; `distressed = late + not-posted`; `percent distressed = distressed amount ÷ due amount × 100`. A payment is never counted in both "posted late" and "not posted": the reconciliation dedups on `(account_id, due_date)` and a posted payment takes precedence. `avg_days_late` is computed by **week posted** (only payments eventually posted contribute), so a payment due five months ago and paid this week counts toward this week's average days late but no bucket.

## API

All endpoints are inferred from the SQRL and served over GraphQL; MCP tools are auto-generated from the same model (`compiler.api.protocols = ["GRAPHQL", "MCP"]`). The GraphQL endpoint is `http://localhost:8888/v1/graphql` (GraphiQL at `.../graphiql`), MCP at `http://localhost:8888/v1/mcp/`.

| Operation | Kind | Description |
|---|---|---|
| `ZipWeeklyAgg(week_start, zip_code, state)` | query table | Weekly distress measures per zip (R1), all bucket counts/amounts. |
| `CustomerWeeklyAgg(week_start, customer_id, zip_code)` | query table | The same measures per customer (R2). |
| `ZipOverview(zip_code, state)` | query table | One row per zip over the last two complete weeks, with week-over-week trends (R7/R8). |
| `ZipOverviewByPrefix(zip_prefix)` | function | Zip codes matching a `LIKE` pattern (pass `981%` for the numeric prefix search; R9/R16). |
| `ZipHistory(zip_code)` | function | 12 most recent complete weeks for the drill-down chart (R12). |
| `ZipDistressSummary(zip_code)` | function | A zip's distressed count and amount for the last two weeks, with week-over-week change (R11). |
| `DistressedCustomers(zip_code)` | function | Customers in the zip with ≥1 distressed payment over the last two weeks, most-distressed first (R11/R13/R14). |

**Trend semantics** (R8/R11): amounts and average days late use percentage change `(cur − prev) / prev × 100`; percent distressed uses percentage-point difference `cur − prev`. Both are `NULL` when the prior value is `NULL` (or zero, for percentage change).

## Data quality and observability

- **`DQ_UnresolvedObligation`** — one row per obligation whose account or customer/geography did not resolve (e.g. a payment whose `loan_id` has no matching loan). A non-empty result means records are being dropped or mis-bucketed; investigate the named key and reason.
- **`DQ_NegativeAmount`** — one row per payment/delinquency record with a non-positive amount. These are excluded from the buckets so percent-distressed stays within 0–100%.
- **`OB_SourceIngestionStats`** — records ingested per source per run. A missing source row, or a count that drops unexpectedly, makes an input problem visible. (Nightly batch, so counts are per-run/day rather than per-hour.)

Catalog-level validity (valid `loan_type`/`event_type`/`payment_status`, customer/address referential integrity) is covered by the catalog's own build-time `/*+test(no_rows)*/` assertions and is not duplicated here.

## Assumptions and discrepancies

- **Week definition** is Sunday-start (this Flink's `FLOOR(<date> TO WEEK)`), not Monday-start as the plan's Technical Decisions note suggests. This is purely cosmetic — all week boundaries in the config (`window_start`, `cur_week_start`, `prev_week_start`, `history_start`) are Sunday dates and are internally consistent. The plan's own Test Data Specification already used Sunday labels (`2026-09-06`, `2026-08-30`).
- **`as_of_date` and window boundaries** are `script.config` values (fixed `2026-09-14` in test, the run date in production). The window is the 13 weeks preceding `as_of_date`; the two most recent complete weeks drive the overview/trend and the customer drill-down.
- **Reconciliation key** is `(account_id, due_date)`; a `MISSED_PAYMENT` event's implied due date is its `event_date`. **Primary borrower** comes from `primary_borrower_customer_id` (loans), `Mortgage_Borrower.borrower_type = 'PRIMARY'` (mortgages), `Credit_Card_Account.primary_customer_id` (cards).
- **Payment/status filters**: only `APPLIED` (loans/mortgage) and `POSTED` (cards) payments count; only `MISSED_PAYMENT` delinquency events count.
- **Full name** is `CONCAT(first_name, ' ', last_name)` from the customer master (the catalog's `Customer_Profile` is not needed).
- **`avg_days_late`** is `DOUBLE` (e.g. `53.33`); it is `NULL` when no late payments were posted that week. **`percent_distressed`** is `NULL` when nothing was due.
- **Prefix search** is a `LIKE` pattern argument rather than an `=` filter, because SQRL dynamic parameters cannot appear inside `CONCAT`/`UPPER`/`||`; the UI appends `%`.

## Project layout

```
pipeline.sqrl                       # main script: normalize → reconcile → aggregate → API + DQ/OB + tests
connectors/sources.sqrl             # namespaced imports of the catalog's _schema tables
connectors/sources-test.sqrl        # filesystem connectors over connectors/test-data/
connectors/sources-prod.sqrl        # bounded Kafka connectors
connectors/test-data/*.jsonl        # controlled test data exercising every acceptance criterion
api/tests/*.graphql                 # one API test per operation
distressed-shared-package.json      # base config (flink+postgres+vertx, batch, include data-catalog)
distressed-test-package.json        # test overlay (as_of_date, window, test-runner)
distressed-prod-package.json        # prod overlay (deployment sizing, is_batch)
run-tests.sh                        # entry point for the test suite
```

## Dashboard UI

A read-only SPA lives in [`ui/`](ui/) (Vite + React + TanStack React Table + Tremor + Tailwind). It renders the per-zip overview table with the text search field (numeric → zip prefix, alphabetic → state) and sortable columns, and clicking a zip drills into a 12-week chart, the zip's distressed count/amount summary, and a sortable table of distressed customers — all fetched from the GraphQL API and auto-refreshed every 10 seconds. See [`ui/README.md`](ui/README.md) for run instructions.

## Compile, test, run

The project sits in a repository alongside the read-only `data-catalog` module, so the compiler is pointed at this project with `-r distressed_loan_dashboard` (run `run-tests.sh` from this directory).

```bash
# Run the full test suite (table + API snapshot tests)
./run-tests.sh

# Compile the test configuration
docker run --rm -v "$(dirname "$PWD")":/workspace datasqrl/cmd compile \
  -r distressed_loan_dashboard distressed-shared-package.json distressed-test-package.json -b distressed

# Run the pipeline locally (GraphQL at http://localhost:8888/v1/graphiql, Flink UI at http://localhost:8081)
docker run -it --rm -p 8888:8888 -p 8081:8081 -v "$(dirname "$PWD")":/workspace datasqrl/cmd run \
  -r distressed_loan_dashboard distressed-shared-package.json distressed-test-package.json -b distressed
```
