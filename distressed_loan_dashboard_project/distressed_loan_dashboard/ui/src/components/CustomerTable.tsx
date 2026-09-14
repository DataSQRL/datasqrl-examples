import type { ColumnDef } from "@tanstack/react-table";
import { useMemo } from "react";
import type { ZipCustomerDistressRow } from "../lib/api";
import { formatCents, formatDays, formatPctChange, formatPercent, trendColor } from "../lib/format";
import { SortableTable } from "./SortableTable";

interface CustomerTableProps {
  rows: ZipCustomerDistressRow[];
}

// R13/R14: customers in the selected zip with at least one distressed
// payment, sortable by any column so the most distressed customers can be
// brought to the top (default sort).
export function CustomerTable({ rows }: CustomerTableProps) {
  const columns = useMemo<ColumnDef<ZipCustomerDistressRow, any>[]>(
    () => [
      { header: "Customer ID", accessorKey: "customer_id" },
      {
        header: "Name",
        id: "name",
        accessorFn: (r) => `${r.first_name} ${r.last_name}`,
      },
      { header: "Type", accessorKey: "customer_type" },
      { header: "Status", accessorKey: "customer_status" },
      { header: "Since", accessorKey: "relationship_start_date" },
      { header: "City", accessorKey: "city", cell: (c) => c.getValue() ?? "—" },
      {
        header: "Payments due",
        accessorKey: "payments_due_amount_cents_current",
        cell: (c) => formatCents(c.getValue()),
      },
      {
        header: "Posted late",
        accessorKey: "posted_late_amount_cents_current",
        cell: (c) => formatCents(c.getValue()),
      },
      {
        header: "Not posted",
        accessorKey: "not_posted_amount_cents_current",
        cell: (c) => formatCents(c.getValue()),
      },
      {
        header: "Distressed",
        accessorKey: "distressed_amount_cents_current",
        cell: (c) => (
          <div>
            <div>{formatCents(c.getValue())}</div>
            <div className={`text-xs ${trendColor(c.row.original.distressed_amount_pct_change)}`}>
              {formatPctChange(c.row.original.distressed_amount_pct_change)}
            </div>
          </div>
        ),
      },
      {
        header: "% distressed",
        accessorKey: "pct_distressed_current",
        cell: (c) => formatPercent(c.getValue()),
      },
      {
        header: "Avg days late",
        accessorKey: "avg_days_late_current",
        cell: (c) => formatDays(c.getValue()),
      },
    ],
    [],
  );

  return (
    <SortableTable
      data={rows}
      columns={columns}
      defaultSorting={[{ id: "distressed_amount_cents_current", desc: true }]}
      rowKey={(row) => row.customer_id}
    />
  );
}
