# Distressed Loan Dashboard UI

A read-only single-page application for the Distressed Loan Dashboard pipeline. It shows a per-zip overview of the last two complete weeks (with week-over-week trends), lets you filter by zip-code prefix or state and sort by any column, and drills into a zip to see a 12-week chart, the zip's distressed count/amount, and a sortable table of its distressed customers.

Built with **Vite + React**, **TanStack React Table** (sortable tables), **Tremor** (the 12-week chart), and **Tailwind CSS**. Data is fetched over GraphQL with `graphql-request` (a lightweight GraphQL client — Refine's data-provider abstraction is unnecessary for a read-only dashboard).

## Run locally

1. Start the DataSQRL pipeline (from the project root), which serves the GraphQL API:
   ```bash
   docker run -it --rm -p 8888:8888 -p 8081:8081 -v "$(dirname "$PWD")":/workspace datasqrl/cmd run \
     -r distressed_loan_dashboard distressed-shared-package.json distressed-test-package.json -b distressed
   ```
2. In this `ui/` folder, install and start the dev server:
   ```bash
   npm install
   npm run dev
   ```
3. Open http://localhost:5173. The app queries `http://localhost:8888/v1/graphql` by default.

The API URL is configurable with the `VITE_API_URL` environment variable, e.g.
`VITE_API_URL=https://your-production-domain.com/v1/graphql npm run dev`.

## Behavior

- The search field filters the overview: numeric input shows zip codes starting with that prefix (e.g. `981`), alphabetic input shows all zip codes in that state (e.g. `PA`), empty shows every zip.
- Every column header sorts ascending/descending on click (click again to reverse).
- Clicking a zip code loads its 12-week chart, distressed count/amount summary, and customer table below.
- Data auto-refreshes every 10 seconds.
