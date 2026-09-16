import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { parse } from "graphql";
import { dataProvider, API_URL } from "./dataProvider";

// Generic fetch hook built on Refine's GraphQL data provider: every view in
// this app calls its own query through here rather than through the CRUD
// helpers, since none of this API's queries follow a pluralized-resource
// naming convention.
export function useGraphQL<T>(
  gqlQuery: string,
  variables: Record<string, unknown> = {},
  options?: { pollMs?: number; skip?: boolean },
) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const variablesKey = JSON.stringify(variables);
  const document = useMemo(() => parse(gqlQuery), [gqlQuery]);

  const fetchData = useCallback(async () => {
    if (options?.skip) return;
    try {
      const result = await dataProvider.custom!({
        url: API_URL,
        method: "get",
        meta: { gqlQuery: document, gqlVariables: JSON.parse(variablesKey) },
      });
      setData(result.data as T);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Request failed");
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [document, variablesKey, options?.skip]);

  const pollMsRef = useRef(options?.pollMs);
  pollMsRef.current = options?.pollMs;

  useEffect(() => {
    setLoading(true);
    fetchData();
    const pollMs = pollMsRef.current;
    if (pollMs) {
      const id = setInterval(fetchData, pollMs);
      return () => clearInterval(id);
    }
  }, [fetchData]);

  return { data, error, loading, refetch: fetchData };
}

export interface DashboardRun {
  run_scope: string;
  as_of_date: string;
  current_week_start: string;
  current_week_end: string;
  prior_week_start: string;
  chart_window_start: string;
  window_start_date: string;
  window_end_date: string;
  computed_at: string;
}

export const DASHBOARD_RUN_QUERY = `
  query DashboardRunBanner {
    DashboardRun {
      run_scope
      as_of_date
      current_week_start
      current_week_end
      prior_week_start
      window_start_date
      window_end_date
      computed_at
    }
  }
`;

export interface ZipOverviewRow {
  zip_code: string;
  state: string | null;
  current_week_start: string;
  prior_week_start: string;
  payments_due_amount_cents_current: number;
  payments_due_amount_cents_prior: number;
  posted_late_amount_cents_current: number;
  posted_late_amount_cents_prior: number;
  not_posted_amount_cents_current: number;
  not_posted_amount_cents_prior: number;
  distressed_amount_cents_current: number;
  distressed_amount_cents_prior: number;
  distressed_count_current: number;
  distressed_count_prior: number;
  pct_distressed_current: number | null;
  pct_distressed_prior: number | null;
  avg_days_late_current: number | null;
  avg_days_late_prior: number | null;
  payments_due_amount_pct_change: number | null;
  posted_late_amount_pct_change: number | null;
  not_posted_amount_pct_change: number | null;
  distressed_amount_pct_change: number | null;
  distressed_count_pct_change: number | null;
  avg_days_late_pct_change: number | null;
  pct_distressed_point_change: number | null;
}

const ZIP_OVERVIEW_FIELDS = `
  zip_code
  state
  current_week_start
  prior_week_start
  payments_due_amount_cents_current
  payments_due_amount_cents_prior
  posted_late_amount_cents_current
  posted_late_amount_cents_prior
  not_posted_amount_cents_current
  not_posted_amount_cents_prior
  distressed_amount_cents_current
  distressed_amount_cents_prior
  distressed_count_current
  distressed_count_prior
  pct_distressed_current
  pct_distressed_prior
  avg_days_late_current
  avg_days_late_prior
  payments_due_amount_pct_change
  posted_late_amount_pct_change
  not_posted_amount_pct_change
  distressed_amount_pct_change
  distressed_count_pct_change
  avg_days_late_pct_change
  pct_distressed_point_change
`;

export const ZIP_OVERVIEW_QUERY = `
  query ZipOverviewAll {
    ZipOverview {
      ${ZIP_OVERVIEW_FIELDS}
    }
  }
`;

export const ZIP_OVERVIEW_BY_STATE_QUERY = `
  query ZipOverviewByState($state: String) {
    ZipOverview(state: $state) {
      ${ZIP_OVERVIEW_FIELDS}
    }
  }
`;

export const ZIP_OVERVIEW_BY_PREFIX_QUERY = `
  query ZipOverviewByPrefixSearch($zip_prefix: String!) {
    ZipOverviewByPrefix(zip_prefix: $zip_prefix) {
      ${ZIP_OVERVIEW_FIELDS}
    }
  }
`;

export interface ZipWeeklyRow {
  zip_code: string;
  week_start_date: string;
  posted_on_time_amount_cents: number;
  distressed_amount_cents: number;
  distressed_count: number;
  pct_distressed: number | null;
  avg_days_late: number | null;
}

export const ZIP_WEEKLY_HISTORY_QUERY = `
  query ZipWeeklyHistoryChart($zip_code: String!) {
    ZipWeeklyHistory(zip_code: $zip_code) {
      zip_code
      week_start_date
      posted_on_time_amount_cents
      distressed_amount_cents
      distressed_count
      pct_distressed
      avg_days_late
    }
  }
`;

export interface ZipCustomerDistressRow {
  zip_code: string;
  customer_id: string;
  first_name: string;
  last_name: string;
  customer_type: string;
  customer_status: string;
  relationship_start_date: string;
  city: string | null;
  state: string | null;
  distressed_amount_cents_current: number;
  distressed_amount_cents_prior: number;
  distressed_count_current: number;
  distressed_count_prior: number;
  payments_due_amount_cents_current: number;
  posted_late_amount_cents_current: number;
  not_posted_amount_cents_current: number;
  pct_distressed_current: number | null;
  avg_days_late_current: number | null;
  distressed_amount_pct_change: number | null;
  distressed_count_pct_change: number | null;
}

export const ZIP_CUSTOMER_DISTRESS_QUERY = `
  query ZipCustomerDrilldown($zip_code: String!) {
    ZipCustomerDistress(zip_code: $zip_code) {
      zip_code
      customer_id
      first_name
      last_name
      customer_type
      customer_status
      relationship_start_date
      city
      state
      distressed_amount_cents_current
      distressed_amount_cents_prior
      distressed_count_current
      distressed_count_prior
      payments_due_amount_cents_current
      posted_late_amount_cents_current
      not_posted_amount_cents_current
      pct_distressed_current
      avg_days_late_current
      distressed_amount_pct_change
      distressed_count_pct_change
    }
  }
`;
