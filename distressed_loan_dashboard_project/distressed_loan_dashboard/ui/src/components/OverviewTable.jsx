import { useMemo } from 'react';
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  flexRender,
} from '@tanstack/react-table';
import { formatCents, formatPercent, formatTrend } from '../lib/format.js';

function TrendCell({ value, points }) {
  const text = formatTrend(value, { points });
  if (value === null || value === undefined) return <span className="text-slate-400">—</span>;
  const cls = value > 0 ? 'text-red-600' : value < 0 ? 'text-emerald-600' : 'text-slate-500';
  return <span className={cls}>{text}</span>;
}

export default function OverviewTable({ rows, onSelectZip }) {
  const columns = useMemo(
    () => [
      {
        accessorKey: 'zip_code',
        header: 'Zip',
        cell: ({ getValue }) => (
          <button
            className="font-medium text-blue-600 underline hover:text-blue-800"
            onClick={() => onSelectZip(getValue())}
          >
            {getValue()}
          </button>
        ),
      },
      { accessorKey: 'state', header: 'State' },
      {
        id: 'due',
        header: 'Due (cur)',
        accessorFn: (r) => r.cur_due_amount_cents,
        cell: ({ row }) => (
          <div>
            {formatCents(row.original.cur_due_amount_cents)}
            <div className="text-xs text-slate-500">
              <TrendCell value={row.original.due_amount_trend_pct} />
            </div>
          </div>
        ),
      },
      {
        id: 'late',
        header: 'Posted late (cur)',
        accessorFn: (r) => r.cur_late_amount_cents,
        cell: ({ row }) => (
          <div>
            {formatCents(row.original.cur_late_amount_cents)}
            <div className="text-xs text-slate-500">
              <TrendCell value={row.original.late_amount_trend_pct} />
            </div>
          </div>
        ),
      },
      {
        id: 'not_posted',
        header: 'Not posted (cur)',
        accessorFn: (r) => r.cur_not_posted_amount_cents,
        cell: ({ row }) => (
          <div>
            {formatCents(row.original.cur_not_posted_amount_cents)}
            <div className="text-xs text-slate-500">
              <TrendCell value={row.original.not_posted_amount_trend_pct} />
            </div>
          </div>
        ),
      },
      {
        id: 'distressed',
        header: 'Distressed (cur)',
        accessorFn: (r) => r.cur_distressed_amount_cents,
        cell: ({ row }) => (
          <div>
            {formatCents(row.original.cur_distressed_amount_cents)}
            <div className="text-xs text-slate-500">
              <TrendCell value={row.original.distressed_amount_trend_pct} />
            </div>
          </div>
        ),
      },
      {
        id: 'percent',
        header: '% distressed',
        accessorFn: (r) => r.cur_percent_distressed,
        cell: ({ row }) => (
          <div>
            {formatPercent(row.original.cur_percent_distressed)}
            <div className="text-xs text-slate-500">
              <TrendCell value={row.original.percent_distressed_trend_pp} points />
            </div>
          </div>
        ),
      },
      {
        id: 'avg_days',
        header: 'Avg days late',
        accessorFn: (r) => r.cur_avg_days_late,
        cell: ({ row }) => (
          <div>
            {row.original.cur_avg_days_late == null
              ? '—'
              : Number(row.original.cur_avg_days_late).toFixed(1)}
            <div className="text-xs text-slate-500">
              <TrendCell value={row.original.avg_days_late_trend_pct} />
            </div>
          </div>
        ),
      },
    ],
    [onSelectZip],
  );

  const table = useReactTable({
    data: rows,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    initialState: { sorting: [{ id: 'distressed', desc: true }] },
  });

  return (
    <div className="overflow-x-auto rounded-lg border border-slate-200 bg-white shadow-sm">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50">
          {table.getHeaderGroups().map((hg) => (
            <tr key={hg.id}>
              {hg.headers.map((header) => (
                <th
                  key={header.id}
                  onClick={header.column.getToggleSortingHandler()}
                  className="cursor-pointer select-none px-3 py-2 text-left font-semibold text-slate-700"
                >
                  {flexRender(header.column.columnDef.header, header.getContext())}
                  {header.column.getIsSorted()
                    ? header.column.getIsSorted() === 'asc'
                      ? ' ▲'
                      : ' ▼'
                    : ''}
                </th>
              ))}
            </tr>
          ))}
        </thead>
        <tbody className="divide-y divide-slate-100">
          {table.getRowModel().rows.map((row) => (
            <tr key={row.id} className="hover:bg-slate-50">
              {row.getVisibleCells().map((cell) => (
                <td key={cell.id} className="px-3 py-2">
                  {flexRender(cell.column.columnDef.cell, cell.getContext())}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
