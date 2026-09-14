# Distressed Loan Dashboard

A nightly batch pipeline and dashboard that shows, for every zip code and
every customer, how many payments are due, posted on time, posted late, or
not posted at all — and how that is trending week over week. The goal is
to let a bank's servicing and collections teams spot geographies and
customers whose payment distress is worsening, so outreach can be planned
before delinquency becomes default. Planning interventions is in scope;
executing them (outreach, case management) is not — this project computes
and serves the numbers, nothing more.

## Business definitions

Every week is Monday-start, with no time-zone conversion (every date the
pipeline groups by is a SQL `DATE`, not a timestamp).

**Buckets, by week *due*.** Each payment due in a week falls into exactly
one of:
- **Posted on time** — posted on or before its due date.
- **Posted late** — posted after its due date (no grace period: one day
  late is late). This includes a payment that was recorded as a missed
  payment and paid later.
- **Not posted** — not posted, and recorded as a missed-payment event.

**Payments due** = posted on time + posted late + not posted.
**Distressed** = posted late + not posted.
**Percent distressed** = distressed amount ÷ payments due amount, for the
same week — always between 0% and 100%.

A payment is never counted in both posted-late and not-posted. When a
delinquent payment is eventually paid, it moves from not-posted to posted
late — but the **distressed total for that week is stable**: once a
payment enters the distressed bucket, it stays there (R6).

**Average days late, by week *posted*.** The average days late of every
late payment posted during the week, regardless of when it was due —
including a payment due long before the reporting window. This is grouped
by a **different week** than the buckets (week posted, not week due), so
it is not comparable to them; the dashboard labels it accordingly.

**Other rules:**
- Payment amounts are taken as provided in the source data, for every loan
  vehicle including credit cards.
- The customer for a loan with more than one borrower is the primary
  borrower — never a co-borrower named on a delinquency event.
- Geography is the customer's zip code **as it stands when the numbers are
  computed**, applied to the customer's entire history in the window. A
  customer who moves is attributed to the new zip for the whole window on
  the next nightly run (R5) — this is expected, not a bug.
- Partial payments (`payment_type = 'PARTIAL'`) are excluded from every
  bucket for now.

## Architecture

Nightly batch job (Flink `BATCH` mode) → Postgres → GraphQL/REST/MCP API
(Vert.x) → this dashboard.

| Engine | Why it's enabled |
|---|---|
| `flink` | The batch data processor — always on. |
| `postgres` | Serves the database-backed, filterable query/point-lookup endpoints the API needs. |
| `vertx` | Exposes GraphQL, REST and MCP. |

`kafka` and `iceberg` are **not** enabled: there is no mutation, no
`SUBSCRIBE`, and no data-lake output — production reads Kafka topics
through the catalog's own connectors, which does not require the Kafka
engine here.

**Why batch, not streaming.** R3/R4 require a nightly job that recomputes
the whole three-month window and replaces prior results, and R5 requires a
customer's *entire* window history to move to a new zip on the next run —
neither is expressible as an incremental streaming aggregate (a zip change
would have to retract every past week). `execution.runtime-mode: BATCH`
matches this directly.

**The run anchor.** A single table, `_RunAnchor`, holds one pinned or
live `as_of_date` and every week boundary derived from it arithmetically.
In `test` and `local` it is pinned to a fixed date
(`script.config.anchor_date`, currently `2026-09-14`) so snapshots don't
rot as the wall clock advances; in `prod` it follows `CURRENT_DATE`, which
Flink batch mode evaluates once per run. The window is the **13 most
recent complete weeks** (guaranteeing 12 complete weeks are always
covered, per "roughly three months"); the chart shows the most recent 12.
The current, incomplete week is excluded everywhere.

## Data sources

Everything is read from the shared, read-only `data-catalog` module
(sibling directory), included under the `data_catalog` namespace:

| Catalog dataset | What's read |
|---|---|
| `customer.customer_data.customer_master` | `Customer`, `Customer_Address` (current `PRIMARY` address only) |
| `lending.cards_consumer_credit.consumer_loans` | `Personal_Loan`, `Auto_Loan`, `Loan_Payment`, `Consumer_Loan_Delinquency_Event` |
| `lending.cards_consumer_credit.credit_cards` | `Credit_Card_Account`, `Credit_Card_Payment`, `Card_Delinquency_Event` |
| `lending.mortgages.mortgage_originations` | `Mortgage_Loan` |
| `lending.mortgages.mortgage_servicing` | `Mortgage_Payment`, `Delinquency_Event` |

`prod` reads the catalog's own Kafka connectors (`*-prod.sqrl`, wildcard
imported so table names stay bare); `test` and `local` read this
project's own filesystem connectors (`connectors/sources-test.sqrl`),
declared with `LIKE` against the catalog's schema tables and populated
with project-owned test data (`connectors/test-data/*.jsonl`) dense enough
to exercise a 13-week, 6-zip, 3-state, 4-instrument-type window — the
catalog's own lending test data (7 payments, 1 delinquency event per
dataset, all dated 2023–2024) cannot. `local` reuses the `test` connectors
and anchor so the pipeline can be run and the UI developed against
deterministic data.

Datasets **not** read: `kyc_aml`, `customer_enriched`, `credit_risk_signals`,
`mortgage_performance`, and the whole `deposits_payments` line of
business — nothing in R1–R17 references risk ratings, household segments,
balances, or deposit transactions.

## Data quality and observability

Nine `DQ_` capture tables collect records the pipeline could not process
as expected; two `OB_` tables report volume and classification counts over
time. Every table has its own `/*+query_by_any*/` filter and its own
`/*+test*/` snapshot.

| Table | One row / one count means |
|---|---|
| `DQ_Payment_Unknown_Instrument` | A posted payment whose loan/account record doesn't exist — silently absent from every bucket otherwise. |
| `DQ_Delinquency_Unknown_Instrument` | A missed-payment event whose loan/account record doesn't exist. |
| `DQ_Payment_Missing_Dates` | A payment that can't be bucketed: missing due date or missing posted date. |
| `DQ_Payment_DaysLate_Mismatch` | Derived days-late disagrees with the source's own lateness field — the runtime guard on "no grace periods apply." |
| `DQ_Delinquency_Missing_Amount` | A missed-payment event with a null/zero amount past due — counted, but understates the week's amount. |
| `DQ_Delinquency_Customer_Mismatch` | A missed-payment event whose own `customer_id` differs from the instrument's primary borrower (attribution always follows the primary borrower). |
| `DQ_Customer_Missing_Zip` | A customer with payment activity in the window but no current `PRIMARY` address — vanishes from zip rollups. |
| `DQ_Address_Missing_State` | A customer's current primary address has a null/blank state — unreachable by the state search even though it's in the unfiltered table. |
| `DQ_ZipWeekly_Invariant_Violation` | A zip-week that violates one of the three build-time invariants below, at runtime. Should always be empty. |
| `OB_SourceIngestionStats` | Hourly record counts per raw source, before dedup/filtering. Customer and address feeds are sparse by nature — empty hours there are normal. |
| `OB_PaymentClassificationStats` | Row/amount counts per (instrument type, week due, classification) — shows how much input each run drops and why, and doubles as the per-loan-vehicle breakdown open question 2 asked for. |

Three invariants are also asserted at build time as `/*+test(no_rows)*/`
tables (percent distressed outside [0, 100]; posted-on-time + distressed
≠ payments due; a zip's figures ≠ the sum of its customers' figures) —
`DQ_ZipWeekly_Invariant_Violation` is their runtime counterpart.

The catalog's own build-time source-data assertions
(`data-catalog/customer/customer_ontology.sqrl`) live in that read-only
sibling module and are not duplicated here. The catalog's lending side
(`lending-ontology.sqrl`) declares relationships only, with no assertions
at all — a gap worth closing upstream, not something this project can fix.

## API contract

The GraphQL schema is **inferred** from the SQRL definitions (no static
schema file); `compiler.api.endpoints = FULL` exposes every table and
function as a GraphQL query, a REST endpoint, and an MCP tool in one step.
Read the schema at `build/<sub-project>/inferred_schema.graphqls` after a
compile — that file is authoritative, not this document.

Two deliberate deviations from a "plain" inferred API:

1. **Sorting is client-side.** SQRL does not generate dynamic sort
   arguments, and every result set here (zip codes matching one filter,
   customers of one zip) is small. `compiler.api.default-limit` is raised
   to 1000 so the dashboard gets the full filtered set in one call and
   sorts it in the browser.
2. **The zip search (R9) is two operations, not one.** `ZipOverview` takes
   an optional `state` equality filter; `ZipOverviewByPrefix` takes a
   required prefix and does a `STARTSWITH` match. The UI picks between
   them by whether the first character of the input is a digit. This
   gives an MCP agent two unambiguous tools instead of one overloaded
   string argument.

## Dashboard

See [`ui/README.md`](ui/README.md) for how to run it. It shows a
zip-code overview table (state, current/prior week amounts, trends,
percent distressed, average days late) with a prefix-or-state search box
and click-to-sort columns; clicking a zip row shows a 12-week chart, a
two-week distressed summary, and a sortable customer table limited to
customers with a distressed payment in the last two weeks.

## Assumptions (resolved open questions)

Every open question in the requirements is resolved with a concrete
default; the full rationale for each is in `adr/plan_20260914-181146.md`
under `## Assumptions`. In summary:

1. **Customer table window**: last two complete weeks with trend, mirroring the overview.
2. **Loan vehicle breakout**: not on the dashboard; available via `OB_PaymentClassificationStats`.
3. **Access/privacy**: no auth in v1; `@spii` fields (SSN, TIN, DOB) are never read from the catalog.
4. **Week definition**: Monday-start, no time zone, most recent *complete* weeks only.
5. **Window length**: 13 complete weeks; chart shows the most recent 12.
6. **Empty values**: null, not zero — rendered as an em dash.
7. **Customer fields shown**: ID, name, type, status, relationship start date, city, state, zip.
8. **Chart layout**: three vertically aligned charts, average days late explicitly labeled "by week posted."
9. **Default sort**: current-week distressed amount descending.
10. **State input**: two-letter code, case-insensitive; digit-first input is treated as a zip prefix instead.
11. **API/MCP**: auto-generated MCP tools (`Get` prefix), no agent auth in v1.
12. **Scale**: up to 5M payments / 500K customers in the window, ≤50 concurrent users.
13. **Job failure**: a failed run leaves the previous run's results serving; `DashboardRun.computed_at` shows staleness in the header banner.

## Compile, test, run

Every command below runs from the **repository root** (the directory that
contains both `distressed_loan_dashboard/` and the read-only `data-catalog`
sibling), so the shared catalog module is visible inside the container.

```bash
# Compile (local environment)
docker run -it --rm -v $PWD:/workspace datasqrl/cmd \
  compile -r distressed_loan_dashboard \
  distressed_loan_dashboard/distress_dashboard-shared-package.json \
  distressed_loan_dashboard/distress_dashboard-local-package.json \
  -b distress_dashboard

# Test (test environment; snapshots under distressed_loan_dashboard/snapshots/distress_dashboard)
docker run -it --rm -v $PWD:/workspace datasqrl/cmd \
  test -r distressed_loan_dashboard \
  distressed_loan_dashboard/distress_dashboard-shared-package.json \
  distressed_loan_dashboard/distress_dashboard-test-package.json \
  -b distress_dashboard

# Run locally — serves the dashboard's API
docker run -it --rm -p 8888:8888 -p 8081:8081 -v $PWD:/workspace datasqrl/cmd \
  run -r distressed_loan_dashboard \
  distressed_loan_dashboard/distress_dashboard-shared-package.json \
  distressed_loan_dashboard/distress_dashboard-local-package.json \
  -b distress_dashboard
```

Or, from inside `distressed_loan_dashboard/`, run every suite with:

```bash
./run-tests.sh
```

Once `run` is up:
- GraphQL: `http://localhost:8888/v1/graphiql/`
- REST (Swagger UI): `http://localhost:8888/v1/swagger-ui`
- MCP: `http://localhost:8888/v1/mcp/`
- Flink WebUI: `http://localhost:8081/`

Then point the dashboard's dev server (`cd ui && npm run dev`) at
`http://localhost:8888/v1/graphql` — see [`ui/README.md`](ui/README.md).
