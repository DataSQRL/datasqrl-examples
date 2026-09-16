import { Client, cacheExchange, fetchExchange } from "@urql/core";
import createDataProvider from "@refinedev/graphql";

export const API_URL =
  import.meta.env.VITE_GRAPHQL_URL ?? "http://localhost:8888/v1/graphql";

const client = new Client({
  url: API_URL,
  exchanges: [cacheExchange, fetchExchange],
});

// The API's queries (ZipOverview, ZipWeeklyHistory, ...) don't follow the
// pluralized-resource-name convention refine-graphql's default options
// assume, so every call in this project goes through `custom` with an
// explicit query string and variables rather than the CRUD helpers.
export const dataProvider = createDataProvider(client, {
  custom: {
    buildVariables: (params) => params.meta?.gqlVariables ?? {},
    dataMapper: (response) => response.data,
  },
});
