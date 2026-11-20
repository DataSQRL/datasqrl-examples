# Spending Insights UI

A single-page staff web application for the Spending Insights API. It has five screens — customer
search, month overview, categories, recurring payments, and large purchases — and reads every
number from a named API operation (it performs no aggregation of its own). A staff JWT is pasted at
sign-in and held in shared state so every screen follows the opened customer.

## Run locally

Requires Node.js 18+ and npm.

```bash
npm ci
npm run dev          # http://localhost:5173
```

The API URL defaults to `http://localhost:8888/v1/graphql` (the local DataSQRL server). Override it
with the `VITE_API_URL` environment variable at build time:

```bash
VITE_API_URL=https://your-production-domain.com/v1/graphql npm run build
```

## Build

```bash
npm ci
npm run build
```
