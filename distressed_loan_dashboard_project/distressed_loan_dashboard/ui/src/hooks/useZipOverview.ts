import { useState } from "react";
import {
  ZIP_OVERVIEW_BY_PREFIX_QUERY,
  ZIP_OVERVIEW_BY_STATE_QUERY,
  ZIP_OVERVIEW_QUERY,
  useGraphQL,
  type ZipOverviewRow,
} from "../lib/api";

// R9: numeric input searches by zip prefix, alphabetic input searches by
// state, empty input shows every zip code. Dispatching between the two
// GraphQL operations (rather than one overloaded argument) is the API
// contract's own design choice — see README "API Contract deviations".
export function useZipOverview() {
  const [search, setSearch] = useState("");
  const trimmed = search.trim();
  const isPrefixSearch = trimmed.length > 0 && /^\d/.test(trimmed);
  const isStateSearch = trimmed.length > 0 && !isPrefixSearch;

  const unfiltered = useGraphQL<{ ZipOverview: ZipOverviewRow[] }>(
    ZIP_OVERVIEW_QUERY,
    {},
    { skip: trimmed.length > 0 },
  );
  const byState = useGraphQL<{ ZipOverview: ZipOverviewRow[] }>(
    ZIP_OVERVIEW_BY_STATE_QUERY,
    { state: trimmed.toUpperCase() },
    { skip: !isStateSearch },
  );
  const byPrefix = useGraphQL<{ ZipOverviewByPrefix: ZipOverviewRow[] }>(
    ZIP_OVERVIEW_BY_PREFIX_QUERY,
    { zip_prefix: trimmed },
    { skip: !isPrefixSearch },
  );

  const rows: ZipOverviewRow[] = isPrefixSearch
    ? (byPrefix.data?.ZipOverviewByPrefix ?? [])
    : isStateSearch
      ? (byState.data?.ZipOverview ?? [])
      : (unfiltered.data?.ZipOverview ?? []);
  const { loading, error, refetch } = isPrefixSearch ? byPrefix : isStateSearch ? byState : unfiltered;

  return {
    search,
    setSearch,
    isPrefixSearch,
    isStateSearch,
    rows,
    loading,
    error,
    refetch,
  };
}
