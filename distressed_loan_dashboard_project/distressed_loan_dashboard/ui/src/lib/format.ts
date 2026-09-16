// Business-definition formatting helpers shared by every table and chart.
// Null values are always rendered as an em dash rather than zero, since a
// null here means "not measured" (nothing due, no late payment), not zero.

const EM_DASH = "—";

export function formatCents(cents: number | null | undefined): string {
  if (cents === null || cents === undefined) return EM_DASH;
  return (cents / 100).toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  });
}

export function formatPercent(value: number | null | undefined): string {
  if (value === null || value === undefined) return EM_DASH;
  return `${value.toFixed(2)}%`;
}

export function formatDays(value: number | null | undefined): string {
  if (value === null || value === undefined) return EM_DASH;
  return value.toFixed(1);
}

export function formatDate(value: string | null | undefined): string {
  if (!value) return EM_DASH;
  return value;
}

// Amounts and average-days-late trends are percentage changes; percent
// distressed's trend is a percentage-point difference. Both render as a
// signed value, per R8.
export function formatPctChange(value: number | null | undefined): string {
  if (value === null || value === undefined) return EM_DASH;
  const sign = value > 0 ? "+" : "";
  return `${sign}${value.toFixed(2)}%`;
}

export function formatPointChange(value: number | null | undefined): string {
  if (value === null || value === undefined) return EM_DASH;
  const sign = value > 0 ? "+" : "";
  return `${sign}${value.toFixed(2)}pp`;
}

export function trendColor(value: number | null | undefined): string {
  if (value === null || value === undefined) return "text-gray-400";
  if (value > 0) return "text-red-600";
  if (value < 0) return "text-green-600";
  return "text-gray-500";
}
