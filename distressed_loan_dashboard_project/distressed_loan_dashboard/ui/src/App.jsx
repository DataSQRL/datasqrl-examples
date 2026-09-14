import { useCallback, useEffect, useRef, useState } from 'react';
import { client, queries } from './lib/graphql.js';
import OverviewTable from './components/OverviewTable.jsx';
import ZipDrilldown from './components/ZipDrilldown.jsx';

const REFRESH_MS = 10000;

export default function App() {
  const [search, setSearch] = useState('');
  const [overview, setOverview] = useState([]);
  const [overviewError, setOverviewError] = useState(null);

  const [selectedZip, setSelectedZip] = useState(null);
  const [history, setHistory] = useState(null);
  const [summary, setSummary] = useState(null);
  const [customers, setCustomers] = useState(null);
  const [drilldownError, setDrilldownError] = useState(null);
  const [drilldownLoading, setDrilldownLoading] = useState(false);

  const loadOverview = useCallback(async () => {
    const value = search.trim();
    try {
      if (value === '') {
        setOverview((await client.request(queries.overview)).ZipOverview);
      } else if (/^[0-9]+$/.test(value)) {
        setOverview(
          (await client.request(queries.overviewByPrefix, { prefix: `${value}%` })).ZipOverviewByPrefix,
        );
      } else {
        setOverview(
          (await client.request(queries.overviewByState, { state: value.toUpperCase() })).ZipOverview,
        );
      }
      setOverviewError(null);
    } catch (e) {
      setOverviewError(`Failed to load overview: ${e.message}`);
    }
  }, [search]);

  const loadDrilldown = useCallback(async (zip) => {
    if (!zip) return;
    setDrilldownLoading(true);
    setDrilldownError(null);
    try {
      const [h, s, c] = await Promise.all([
        client.request(queries.zipHistory, { zip }),
        client.request(queries.zipDistressSummary, { zip }),
        client.request(queries.distressedCustomers, { zip }),
      ]);
      setHistory(h.ZipHistory);
      setSummary(s.ZipDistressSummary[0] || null);
      setCustomers(c.DistressedCustomers);
    } catch (e) {
      setDrilldownError(`Failed to load zip details: ${e.message}`);
    } finally {
      setDrilldownLoading(false);
    }
  }, []);

  // Load the overview on mount and on search change (debounced).
  const firstRun = useRef(true);
  useEffect(() => {
    loadOverview();
    const id = setInterval(loadOverview, REFRESH_MS);
    return () => clearInterval(id);
  }, [loadOverview]);

  // Auto-refresh the drill-down while a zip is selected.
  useEffect(() => {
    if (!selectedZip) return;
    loadDrilldown(selectedZip);
    const id = setInterval(() => loadDrilldown(selectedZip), REFRESH_MS);
    return () => clearInterval(id);
  }, [selectedZip, loadDrilldown]);

  return (
    <div className="min-h-screen bg-slate-100 p-6">
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Distressed Loan Dashboard</h1>
        <p className="text-sm text-slate-500">
          Weekly payment distress by zip code, over the last two complete weeks.
        </p>
      </header>

      <div className="mb-4">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search by zip prefix (981) or state (PA)"
          className="w-full max-w-sm rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none"
        />
        <p className="mt-1 text-xs text-slate-400">
          Numeric input filters by zip-code prefix; letters filter by state.
        </p>
      </div>

      {overviewError && <div className="mb-4 rounded bg-red-50 p-3 text-red-700">{overviewError}</div>}

      <OverviewTable rows={overview} onSelectZip={setSelectedZip} />

      {selectedZip && (
        <ZipDrilldown
          zipCode={selectedZip}
          history={history}
          summary={summary}
          customers={customers}
          loading={drilldownLoading}
          error={drilldownError}
        />
      )}
    </div>
  );
}
