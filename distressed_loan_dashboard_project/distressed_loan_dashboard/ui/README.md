# Distressed Loan Dashboard — UI

A single-page dashboard for the Distressed Loan Dashboard pipeline. It shows,
per zip code, the current and prior week's payment-distress figures with
week-over-week trends, a text search by zip prefix or state, and a
drill-down (12-week chart, two-week distressed summary, and a customer
table) when a zip row is clicked. See the project [README.md](../README.md)
for the business definitions behind these numbers.

Built with Vite + React + TypeScript, Refine (`@refinedev/graphql` on top of
`@urql/core`) for data fetching, Tailwind CSS for styling, Tremor for the
charts, and TanStack Table for the two sortable tables.

## Running locally

1. Start the pipeline (from the project root, in another terminal) so the
   GraphQL API is serving at `http://localhost:8888/v1/graphql`:
   ```bash
   docker run -it --rm -p 8888:8888 -p 8081:8081 -v $PWD:/build datasqrl/cmd \
     run distress_dashboard-shared-package.json distress_dashboard-local-package.json -b distress_dashboard
   ```
2. Install dependencies and start the dev server:
   ```bash
   npm install
   npm run dev
   ```
3. Open the printed local URL (defaults to `http://localhost:5173`).

## Configuration

The GraphQL endpoint is read from the `VITE_GRAPHQL_URL` environment
variable (see `.env.example`), defaulting to `http://localhost:8888/v1/graphql`
for local development. Set it in a `.env` file or in the hosting
environment to point at a different deployment, e.g.:

```
VITE_GRAPHQL_URL=https://your-production-domain.com/v1/graphql
```

## Notes

- Sorting is client-side, on the full result set the API already returns
  (see the project README's "API contract deviations").
- The header banner polls `DashboardRun` every 60 seconds and refetches the
  dashboard when the run's `computed_at` changes, since the data only
  changes once a night.
- A failed API call shows a visible error message inline rather than an
  empty table.
