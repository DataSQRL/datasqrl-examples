import { useMemo } from 'react';
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  flexRender,
} from '@tanstack/react-table';
import { formatCents, formatPercent } from '../lib/format.js';

export default function CustomerTable({ rows }) {
  const columns = useMemo(
    () => [
      { accessorKey: 'customer_id', header: 'Customer ID' },
      { accessorKey: 'full_name', header: 'Name' },
      { accessorKey: 'due_count', header: 'Due count' },
      {
        id: 'due_amount',
        accessorFn: (r) => r.due_amount_cents,
        cell: ({ getValue }) => formatCents(getValue()),
        header: 'Due amount',
      },
      { accessorKey: 'distressed_count', header: 'Distressed count' },
      {
        id: 'distressed_amount',
        accessorFn: (r) => r.distressed_amount_cents,
        cell: ({ getValue }) => formatCents(getValue()),
        header: 'Distressed amount',
      },
      {
        accessorKey: 'percent_distressed',
        header: '% distressed',
        cell: ({ getValue }) => formatPercent(getValue()),
      },
      {
        accessorKey: 'avg_days_late',
        header: 'Avg days late',
        cell: ({ getValue }) => (getValue() == null ? '—' : Number(getValue()).toFixed(1)),
      },
    ],
    [],
  );

  const table = useReactTable({
    data: rows,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    initialState: { sorting: [{ id: 'distressed_amount', desc: true }] },
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
