# Credit Card Analytics Dashboard

A React-based single-page application (SPA) for visualizing and analyzing credit card transaction data. This internal operations portal provides comprehensive analytics for customer spending patterns and transaction history.

## Features

- **Customer Analytics Search**: Enter customer ID and date range to view detailed analytics
- **Spending by Category**: Interactive line chart showing weekly spending trends across different categories
- **Daily Spending Overview**: Line chart visualizing day-by-day spending patterns
- **Transaction History**: Detailed table view of all transactions with filtering capabilities

## Tech Stack

- **React 18** - UI framework
- **Vite** - Build tool and dev server
- **Urql** - GraphQL client for API communication
- **Recharts** - Data visualization library
- **date-fns** - Date formatting and manipulation

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- GraphQL API running at `http://localhost:8888/v1/graphql`

## Installation

```bash
npm install
```

## Configuration

The application uses environment variables for configuration. Create a `.env` file in the root directory:

```bash
# .env
VITE_GRAPHQL_URL=http://localhost:8888/v1/graphql
```

For production, update `.env.production`:

```bash
# .env.production
VITE_GRAPHQL_URL=https://your-production-api.com/v1/graphql
```

**Environment Variables:**

- `VITE_GRAPHQL_URL` - GraphQL API endpoint (required)
  - Development default: `http://localhost:8888/v1/graphql`
  - Production: Configure in `.env.production`

## Development

Start the development server:

```bash
npm run dev
```

The application will be available at `http://localhost:5173/`

## Build

Create a production build:

```bash
npm run build
```

Preview the production build:

```bash
npm run preview
```

## GraphQL API

The application connects to a GraphQL API with the following queries:

### SpendingByCategory
Returns weekly spending aggregated by category for a customer.

### SpendingByDay
Returns daily spending totals for a customer within a specified date range.

### Transactions
Returns detailed transaction records for a customer within a specified date range.

## Default Configuration

- **GraphQL Endpoint**: `http://localhost:8888/v1/graphql`
- **Default Date Range**: 2024-05-05 to 2024-06-05
- **Default Customer ID**: 1

## Project Structure

```
frontend/
├── src/
│   ├── App.jsx          # Main application component
│   ├── App.css          # Application styles
│   ├── main.jsx         # Application entry point with GraphQL provider
│   └── index.css        # Global styles
├── index.html           # HTML template
├── vite.config.js       # Vite configuration
└── package.json         # Dependencies and scripts
```

## Claude Code Prompt

In the folder @finance-credit-card-chatbot/credit-card-analytics/frontend implement a SPA (Vite + React + Apollo/Urql) that is a frontend to the graphql api defined in
@finance-credit-card-chatbot/credit-card-analytics/schema.v1.graphqls which is running on http://localhost:8888/v1/graphql. Make it look like an internal banking app where
the user enters customerid and (optionally) a time range with date selectors for fromTime and toTime. By default, toTime is 2024-06-05 and fromTime is 2024-05-05. It shows
visualizations for all three queries: spending by category as a line chart (with a different line for each category and week on the x axis, spending on the y), spending by
day as a line chart (day x-axis, spending y) and transactions as a table. Use suitable visualization libraries to keep the code concise. Test the SPA to make sure it works
against the running api.