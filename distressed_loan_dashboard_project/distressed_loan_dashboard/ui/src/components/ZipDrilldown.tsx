import { AreaChart, LineChart } from "@tremor/react";
import {
  ZIP_CUSTOMER_DISTRESS_QUERY,
  ZIP_WEEKLY_HISTORY_QUERY,
  useGraphQL,
  type ZipCustomerDistressRow,
  type ZipOverviewRow,
  type ZipWeeklyRow,
} from "../lib/api";
import { formatCents, formatPctChange, trendColor } from "../lib/format";
import { CustomerTable } from "./CustomerTable";

interface ZipDrilldownProps {
  zipCode: string;
  overviewRow: ZipOverviewRow | undefined;
}

function SummaryTile({
  label,
  current,
  change,
}: {
  label: string;
  current: string;
  change: number | null;
}) {
  return (
    <div className="rounded border border-gray-200 bg-white px-4 py-3 shadow-sm">
      <div className="text-xs uppercase tracking-wide text-gray-500">{label}</div>
      <div className="text-2xl font-semibold text-gray-900">{current}</div>
      <div className={`text-sm ${trendColor(change)}`}>{formatPctChange(change)} week over week</div>
    </div>
  );
}

// R11/R12: the 12-week chart, the two-week distressed summary, and the
// customer table for one zip code, shown below the overview when a row is
// clicked. The two-week summary reuses the current/prior figures already
// fetched for the overview row (the same current/prior week definition),
// rather than picking the last two entries out of the chart series, which
// can be sparse for a zip with no activity in the most recent week(s).
export function ZipDrilldown({ zipCode, overviewRow }: ZipDrilldownProps) {
  const history = useGraphQL<{ ZipWeeklyHistory: ZipWeeklyRow[] }>(ZIP_WEEKLY_HISTORY_QUERY, {
    zip_code: zipCode,
  });
  const customers = useGraphQL<{ ZipCustomerDistress: ZipCustomerDistressRow[] }>(
    ZIP_CUSTOMER_DISTRESS_QUERY,
    { zip_code: zipCode },
  );

  const weeks = (history.data?.ZipWeeklyHistory ?? []).map((w) => ({
    week: w.week_start_date,
    "Posted on time ($)": w.posted_on_time_amount_cents / 100,
    "Distressed ($)": w.distressed_amount_cents / 100,
    "% distressed": w.pct_distressed,
    "Avg days late": w.avg_days_late,
  }));

  return (
    <div className="mt-6 rounded border border-gray-200 bg-gray-50 p-4">
      <h2 className="mb-4 text-lg font-semibold text-gray-800">Zip {zipCode} — 12-week detail</h2>

      {history.error && (
        <div className="mb-3 rounded bg-red-50 px-3 py-2 text-sm text-red-700">
          Failed to load history: {history.error}
        </div>
      )}

      {!history.loading && weeks.length > 0 && (
        <div className="mb-6 grid grid-cols-1 gap-4 md:grid-cols-3">
          <div className="rounded border border-gray-200 bg-white p-3 shadow-sm">
            <div className="mb-2 text-sm font-medium text-gray-700">Amounts by week due</div>
            <AreaChart
              data={weeks}
              index="week"
              categories={["Posted on time ($)", "Distressed ($)"]}
              colors={["emerald", "red"]}
              valueFormatter={(v: number) => `$${Math.round(v).toLocaleString()}`}
              yAxisWidth={80}
              className="h-48"
            />
          </div>
          <div className="rounded border border-gray-200 bg-white p-3 shadow-sm">
            <div className="mb-2 text-sm font-medium text-gray-700">Percent distressed by week due</div>
            <LineChart
              data={weeks}
              index="week"
              categories={["% distressed"]}
              colors={["red"]}
              yAxisWidth={40}
              className="h-48"
            />
          </div>
          <div className="rounded border border-gray-200 bg-white p-3 shadow-sm">
            <div className="mb-2 text-sm font-medium text-gray-700">
              Average days late{" "}
              <span className="font-normal text-gray-400">
                (by week posted — not directly comparable to the charts above)
              </span>
            </div>
            <LineChart
              data={weeks}
              index="week"
              categories={["Avg days late"]}
              colors={["amber"]}
              yAxisWidth={40}
              className="h-48"
            />
          </div>
        </div>
      )}

      {overviewRow && (
        <div className="mb-6 grid grid-cols-2 gap-4 md:w-1/2">
          <SummaryTile
            label="Distressed count (current week)"
            current={String(overviewRow.distressed_count_current)}
            change={overviewRow.distressed_count_pct_change}
          />
          <SummaryTile
            label="Distressed amount (current week)"
            current={formatCents(overviewRow.distressed_amount_cents_current)}
            change={overviewRow.distressed_amount_pct_change}
          />
        </div>
      )}

      <h3 className="mb-2 text-sm font-semibold text-gray-700">
        Customers with a distressed payment in the last two weeks
      </h3>
      {customers.error && (
        <div className="mb-2 rounded bg-red-50 px-3 py-2 text-sm text-red-700">
          Failed to load customers: {customers.error}
        </div>
      )}
      {customers.loading && !customers.data ? (
        <div className="px-3 py-6 text-sm text-gray-400">Loading…</div>
      ) : (
        <CustomerTable rows={customers.data?.ZipCustomerDistress ?? []} />
      )}
    </div>
  );
}
