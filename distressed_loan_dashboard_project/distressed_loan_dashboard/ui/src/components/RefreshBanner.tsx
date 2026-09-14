import { useEffect, useRef } from "react";
import { DASHBOARD_RUN_QUERY, useGraphQL, type DashboardRun } from "../lib/api";

interface RefreshBannerProps {
  onRunChanged: () => void;
}

// Shows when the nightly batch last refreshed the data (open question 13),
// and refetches the dashboard when the run's computed_at changes. Polls
// every 60 seconds — polling every 10 would be wasted against a nightly
// batch job.
export function RefreshBanner({ onRunChanged }: RefreshBannerProps) {
  const { data, error } = useGraphQL<{ DashboardRun: DashboardRun[] }>(
    DASHBOARD_RUN_QUERY,
    {},
    { pollMs: 60_000 },
  );
  const lastComputedAt = useRef<string | null>(null);
  const run = data?.DashboardRun?.[0];

  useEffect(() => {
    if (run && lastComputedAt.current && run.computed_at !== lastComputedAt.current) {
      onRunChanged();
    }
    if (run) lastComputedAt.current = run.computed_at;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [run?.computed_at]);

  if (error) {
    return (
      <div className="bg-red-50 px-4 py-2 text-sm text-red-700">
        Could not load refresh status: {error}
      </div>
    );
  }

  return (
    <div className="flex items-center justify-between bg-slate-800 px-4 py-2 text-sm text-slate-100">
      <span className="font-semibold">Distressed Loan Dashboard</span>
      <span>
        {run
          ? `Data as of ${run.as_of_date} · current week ${run.current_week_start} – ${run.current_week_end}`
          : "Loading refresh status…"}
      </span>
    </div>
  );
}
