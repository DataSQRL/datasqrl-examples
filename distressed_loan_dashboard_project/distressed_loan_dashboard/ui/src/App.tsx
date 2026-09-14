import { useMemo, useState } from "react";
import { RefreshBanner } from "./components/RefreshBanner";
import { ZipDrilldown } from "./components/ZipDrilldown";
import { ZipOverviewTable } from "./components/ZipOverviewTable";
import { useZipOverview } from "./hooks/useZipOverview";

function App() {
  const overview = useZipOverview();
  const [selectedZip, setSelectedZip] = useState<string | null>(null);

  const selectedRow = useMemo(
    () => overview.rows.find((r) => r.zip_code === selectedZip),
    [overview.rows, selectedZip],
  );

  return (
    <div className="min-h-screen">
      <RefreshBanner onRunChanged={overview.refetch} />
      <main className="mx-auto max-w-6xl px-4 py-6">
        <h1 className="mb-4 text-xl font-semibold text-gray-900">Geographic overview</h1>
        <ZipOverviewTable
          rows={overview.rows}
          loading={overview.loading}
          error={overview.error}
          search={overview.search}
          onSearchChange={overview.setSearch}
          isPrefixSearch={overview.isPrefixSearch}
          isStateSearch={overview.isStateSearch}
          selectedZip={selectedZip}
          onSelectZip={(zip) => setSelectedZip(zip === selectedZip ? null : zip)}
        />
        {selectedZip && <ZipDrilldown zipCode={selectedZip} overviewRow={selectedRow} />}
      </main>
    </div>
  );
}

export default App;
