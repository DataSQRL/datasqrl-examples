import { GraphQLClient, gql } from 'graphql-request';

// Configure the API URL via VITE_API_URL (defaults to the local DataSQRL dev server).
export const client = new GraphQLClient(
  import.meta.env.VITE_API_URL || 'http://localhost:8888/v1/graphql',
);

const OVERVIEW_FIELDS = `
  zip_code state cur_week_start prev_week_start
  cur_due_amount_cents prev_due_amount_cents due_amount_trend_pct
  cur_late_amount_cents prev_late_amount_cents late_amount_trend_pct
  cur_not_posted_amount_cents prev_not_posted_amount_cents not_posted_amount_trend_pct
  cur_distressed_amount_cents prev_distressed_amount_cents distressed_amount_trend_pct
  cur_distressed_count prev_distressed_count distressed_count_trend_pct
  cur_percent_distressed prev_percent_distressed percent_distressed_trend_pp
  cur_avg_days_late prev_avg_days_late avg_days_late_trend_pct
`;

export const queries = {
  overview: gql`
    query Overview {
      ZipOverview(limit: 1000) { ${OVERVIEW_FIELDS} }
    }
  `,
  overviewByState: gql`
    query OverviewByState($state: String) {
      ZipOverview(state: $state, limit: 1000) { ${OVERVIEW_FIELDS} }
    }
  `,
  overviewByPrefix: gql`
    query OverviewByPrefix($prefix: String) {
      ZipOverviewByPrefix(zip_prefix: $prefix, limit: 1000) { ${OVERVIEW_FIELDS} }
    }
  `,
  zipHistory: gql`
    query ZipHistory($zip: String) {
      ZipHistory(zip_code: $zip, limit: 100) {
        week_start on_time_amount_cents distressed_amount_cents percent_distressed avg_days_late
      }
    }
  `,
  zipDistressSummary: gql`
    query ZipDistressSummary($zip: String) {
      ZipDistressSummary(zip_code: $zip) {
        zip_code cur_distressed_count prev_distressed_count distressed_count_trend_pct
        cur_distressed_amount_cents prev_distressed_amount_cents distressed_amount_trend_pct
      }
    }
  `,
  distressedCustomers: gql`
    query DistressedCustomers($zip: String) {
      DistressedCustomers(zip_code: $zip, limit: 1000) {
        customer_id full_name due_count due_amount_cents
        distressed_count distressed_amount_cents percent_distressed avg_days_late
      }
    }
  `,
};
