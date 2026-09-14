import {
  type ColumnDef,
  type SortingState,
  flexRender,
  getCoreRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import { useState } from "react";

interface SortableTableProps<T> {
  data: T[];
  columns: ColumnDef<T, any>[];
  defaultSorting: SortingState;
  onRowClick?: (row: T) => void;
  rowKey: (row: T) => string;
  selectedRowKey?: string | null;
}

// Shared by the zip overview table (R10) and the drill-down customer table
// (R14): both need the same click-a-header-to-sort, click-again-to-reverse
// behavior over an already-fetched, small result set.
export function SortableTable<T>({
  data,
  columns,
  defaultSorting,
  onRowClick,
  rowKey,
  selectedRowKey,
}: SortableTableProps<T>) {
  const [sorting, setSorting] = useState<SortingState>(defaultSorting);

  const table = useReactTable({
    data,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
  });

  return (
    <table className="w-full border-collapse text-sm">
      <thead>
        {table.getHeaderGroups().map((headerGroup) => (
          <tr key={headerGroup.id} className="border-b border-gray-200">
            {headerGroup.headers.map((header) => {
              const sortDir = header.column.getIsSorted();
              return (
                <th
                  key={header.id}
                  onClick={header.column.getToggleSortingHandler()}
                  className="cursor-pointer select-none whitespace-nowrap px-3 py-2 text-left font-semibold text-gray-600 hover:bg-gray-50"
                >
                  {flexRender(header.column.columnDef.header, header.getContext())}
                  <span className="ml-1 inline-block w-3 text-gray-400">
                    {sortDir === "asc" ? "▲" : sortDir === "desc" ? "▼" : ""}
                  </span>
                </th>
              );
            })}
          </tr>
        ))}
      </thead>
      <tbody>
        {table.getRowModel().rows.map((row) => (
          <tr
            key={rowKey(row.original)}
            onClick={() => onRowClick?.(row.original)}
            className={`border-b border-gray-100 ${
              onRowClick ? "cursor-pointer hover:bg-blue-50" : ""
            } ${selectedRowKey === rowKey(row.original) ? "bg-blue-50" : ""}`}
          >
            {row.getVisibleCells().map((cell) => (
              <td key={cell.id} className="whitespace-nowrap px-3 py-2">
                {flexRender(cell.column.columnDef.cell, cell.getContext())}
              </td>
            ))}
          </tr>
        ))}
        {table.getRowModel().rows.length === 0 && (
          <tr>
            <td colSpan={columns.length} className="px-3 py-6 text-center text-gray-400">
              No rows match the current filter.
            </td>
          </tr>
        )}
      </tbody>
    </table>
  );
}
