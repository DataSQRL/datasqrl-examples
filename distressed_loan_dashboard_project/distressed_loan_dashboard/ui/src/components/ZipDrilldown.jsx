import { LineChart } from '@tremor/react';
import CustomerTable from './CustomerTable.jsx';
import { formatCents, formatTrend } from '../lib/format.js';

export default function ZipDrilldown({ zipCode, history, summary, customers, loading, error }) {
  const chartData = (history || []).map((h) => ({
    week: h.week_start,
    'On time': (h.on_time_amount_cents || 0) / 100,
    Distressed: (h.distressed_amount_cents || 0) / 100,
    '% distressed': h.percent_distressed ?? 0,
    'Avg days late': h.avg_days_late ?? 0,
  }));

  return (
    <div className="mt-6 space-y-6">
      <h2 className="text-lg font-bold text-slate-800">Zip code {zipCode}</h2>

      {error && <div className="rounded bg-red-50 p-3 text-red-700">{error}</div>}

      {summary && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
            <div className="text-sm font-medium text-slate-500">Distressed amount (last 2 weeks)</div>
            <div className="mt-1 text-2xl font-bold">
              {formatCents(summary.cur_distressed_amount_cents)}
            </div>
            <div className="text-sm">
              prev {formatCents(summary.prev_distressed_amount_cents)} ·{' '}
              <span className="font-medium">{formatTrend(summary.distressed_amount_trend_pct)}</span>
            </div>
          </div>
          <div className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
            <div className="text-sm font-medium text-slate-500">Distressed count (last 2 weeks)</div>
            <div className="mt-1 text-2xl font-bold">{summary.cur_distressed_count}</div>
            <div className="text-sm">
              prev {summary.prev_distressed_count} ·{' '}
              <span className="font-medium">{formatTrend(summary.distressed_count_trend_pct)}</span>
            </div>
          </div>
        </div>
      )}

      <div className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <h3 className="mb-2 font-semibold text-slate-700">12-week trend</h3>
        {loading ? (
          <div className="text-slate-400">Loading…</div>
        ) : (
          <LineChart
            data={chartData}
            index="week"
            categories={['On time', 'Distressed', '% distressed', 'Avg days late']}
            colors={['emerald', 'red', 'amber', 'blue']}
            valueFormatter={(v) => `$${Number(v).toLocaleString()}`}
            yAxisWidth={64}
            className="h-72"
          />
        )}
      </div>

      <div>
        <h3 className="mb-2 font-semibold text-slate-700">Distressed customers</h3>
        {loading ? (
          <div className="text-slate-400">Loading…</div>
        ) : customers && customers.length === 0 ? (
          <div className="rounded-lg border border-slate-200 bg-white p-4 text-slate-500 shadow-sm">
            No distressed customers in this zip code.
          </div>
        ) : (
          <CustomerTable rows={customers || []} />
        )}
      </div>
    </div>
  );
}
