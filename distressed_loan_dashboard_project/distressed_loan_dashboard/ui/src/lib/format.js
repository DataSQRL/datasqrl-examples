// Amounts are stored in cents (BIGINT). Format for display.
export function formatCents(cents) {
  if (cents === null || cents === undefined) return '—';
  return (cents / 100).toLocaleString('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  });
}

// Percent values (e.g. 5.0) → "5.00%"; null → "—".
export function formatPercent(value) {
  if (value === null || value === undefined) return '—';
  return `${Number(value).toFixed(2)}%`;
}

// Trend percentage change (e.g. 150.0 → "+150%") or percentage-point diff.
export function formatTrend(value, { points = false } = {}) {
  if (value === null || value === undefined) return '—';
  const sign = value > 0 ? '+' : '';
  const suffix = points ? ' pp' : '%';
  return `${sign}${Number(value).toFixed(1)}${suffix}`;
}
