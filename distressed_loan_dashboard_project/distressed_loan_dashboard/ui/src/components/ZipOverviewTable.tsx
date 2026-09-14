import type { ColumnDef } from "@tanstack/react-table";
import { useMemo } from "react";
import type { ZipOverviewRow } from "../lib/api";
import { formatCents, formatDays, formatPctChange, formatPercent, formatPointChange, trendColor } from "../lib/format";
import { SortableTable } from "./SortableTable";

interface ZipOverviewTableProps {
  rows: ZipOverviewRow[];
  loading: boolean;
  error: string | null;
  search: string;
  onSearchChange: (value: string) => void;
  isPrefixSearch: boolean;
  isStateSearch: boolean;
  selectedZip: string | null;
  onSelectZip: (zip: string) => void;
}

function trendCell(current: string, change: number | null, changeLabel: string) {
  return (
    <div>
      <div>{current}</div>
      <div className={`text-xs ${trendColor(change)}`}>{changeLabel}</div>
    </div>
  );
}

// R7/R8/R9/R10: one row per zip code, current/prior week amounts with
// trend, a prefix-or-state search box above it, and client-side sorting by
// clicking any column header.
export function ZipOverviewTable({
  rows,
  loading,
  error,
  search,
  onSearchChange,
  isPrefixSearch,
  isStateSearch,
  selectedZip,
  onSelectZip,
}: ZipOverviewTableProps) {
  const trimmed = search.trim();

  const columns = useMemo<ColumnDef<ZipOverviewRow, any>[]>(
    () => [
      { header: "Zip", accessorKey: "zip_code" },
      { header: "State", accessorKey: "state", cell: (c) => c.getValue() ?? "—" },
      {
        header: "Payments due",
        accessorKey: "payments_due_amount_cents_current",
        cell: (c) =>
          trendCell(
            formatCents(c.getValue()),
            c.row.original.payments_due_amount_pct_change,
            formatPctChange(c.row.original.payments_due_amount_pct_change),
          ),
      },
      {
        header: "Posted late",
        accessorKey: "posted_late_amount_cents_current",
        cell: (c) =>
          trendCell(
            formatCents(c.getValue()),
            c.row.original.posted_late_amount_pct_change,
            formatPctChange(c.row.original.posted_late_amount_pct_change),
          ),
      },
      {
        header: "Not posted",
        accessorKey: "not_posted_amount_cents_current",
        cell: (c) =>
          trendCell(
            formatCents(c.getValue()),
            c.row.original.not_posted_amount_pct_change,
            formatPctChange(c.row.original.not_posted_amount_pct_change),
          ),
      },
      {
        header: "Distressed",
        accessorKey: "distressed_amount_cents_current",
        cell: (c) =>
          trendCell(
            formatCents(c.getValue()),
            c.row.original.distressed_amount_pct_change,
            formatPctChange(c.row.original.distressed_amount_pct_change),
          ),
      },
      {
        header: "% distressed",
        accessorKey: "pct_distressed_current",
        cell: (c) =>
          trendCell(
            formatPercent(c.getValue()),
            c.row.original.pct_distressed_point_change,
            formatPointChange(c.row.original.pct_distressed_point_change),
          ),
      },
      {
        header: "Avg days late",
        accessorKey: "avg_days_late_current",
        cell: (c) =>
          trendCell(
            formatDays(c.getValue()),
            c.row.original.avg_days_late_pct_change,
            formatPctChange(c.row.original.avg_days_late_pct_change),
          ),
      },
    ],
    [],
  );

  return (
    <div>
      <div className="mb-3 flex items-center gap-2">
        <input
          type="text"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder='Search zip prefix (e.g. "981") or state (e.g. "PA")'
          className="w-96 rounded border border-gray-300 px-3 py-1.5 text-sm focus:border-blue-400 focus:outline-none"
        />
        {trimmed.length > 0 && (
          <span className="text-xs text-gray-500">
            {isPrefixSearch
              ? `Matching zip codes starting with "${trimmed}"`
              : isStateSearch
                ? `Matching state "${trimmed.toUpperCase()}"`
                : ""}
          </span>
        )}
      </div>
      {error && (
        <div className="mb-2 rounded bg-red-50 px-3 py-2 text-sm text-red-700">
          Failed to load zip overview: {error}
        </div>
      )}
      {loading && rows.length === 0 ? (
        <div className="px-3 py-6 text-sm text-gray-400">Loading…</div>
      ) : (
        <SortableTable
          data={rows}
          columns={columns}
          defaultSorting={[{ id: "distressed_amount_cents_current", desc: true }]}
          onRowClick={(row) => onSelectZip(row.zip_code)}
          rowKey={(row) => row.zip_code}
          selectedRowKey={selectedZip}
        />
      )}
    </div>
  );
}
