import { useCallback, useEffect, useState } from 'react'
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { graphql, setToken, getToken } from './api'

// Every figure on every screen is read from a named API operation; the UI performs no
// arithmetic across responses.

type Screen = 'search' | 'overview' | 'categories' | 'recurring' | 'purchases'

function money(cents: number | null | undefined): string {
  if (cents == null) return '—'
  return `$${(cents / 100).toFixed(2)}`
}

function App() {
  const [token, setTokenState] = useState<string>(getToken() ?? '')
  const [screen, setScreen] = useState<Screen>('search')
  const [customerId, setCustomerId] = useState('CUST-057')
  const [month, setMonth] = useState('2026-08')

  const signIn = (t: string) => {
    setToken(t)
    setTokenState(t)
  }
  const signOut = () => {
    setToken(null)
    setTokenState('')
  }

  if (!token) {
    return <SignIn onSignIn={signIn} />
  }

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900">
      <header className="bg-white shadow p-4 flex items-center gap-4">
        <h1 className="text-lg font-semibold">Spending Insights</h1>
        <nav className="flex gap-2">
          {(['search', 'overview', 'categories', 'recurring', 'purchases'] as Screen[]).map((s) => (
            <button
              key={s}
              onClick={() => setScreen(s)}
              className={`px-3 py-1 rounded ${screen === s ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
            >
              {s}
            </button>
          ))}
        </nav>
        <div className="ml-auto flex items-center gap-3">
          <input
            value={customerId}
            onChange={(e) => setCustomerId(e.target.value)}
            placeholder="customer id"
            className="border rounded px-2 py-1"
          />
          <input
            value={month}
            onChange={(e) => setMonth(e.target.value)}
            placeholder="YYYY-MM"
            className="border rounded px-2 py-1"
          />
          <button onClick={signOut} className="text-sm text-gray-500">sign out</button>
        </div>
      </header>
      <main className="p-6">
        {screen === 'search' && <CustomerSearch customerId={customerId} onOpen={setCustomerId} />}
        {screen === 'overview' && <MonthOverview customerId={customerId} month={month} />}
        {screen === 'categories' && <Categories customerId={customerId} month={month} />}
        {screen === 'recurring' && <Recurring customerId={customerId} />}
        {screen === 'purchases' && <Purchases customerId={customerId} />}
      </main>
    </div>
  )
}

function SignIn({ onSignIn }: { onSignIn: (t: string) => void }) {
  const [value, setValue] = useState('')
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="bg-white p-6 rounded shadow w-96">
        <h1 className="text-lg font-semibold mb-4">Sign in</h1>
        <p className="text-sm text-gray-500 mb-4">
          Paste a staff JWT (issuer <code>spending-insights</code>, audience{' '}
          <code>spending-console</code>).
        </p>
        <textarea
          value={value}
          onChange={(e) => setValue(e.target.value)}
          className="w-full border rounded p-2 text-xs font-mono"
          rows={6}
        />
        <button
          onClick={() => onSignIn(value.trim())}
          className="mt-4 w-full bg-blue-600 text-white py-2 rounded"
        >
          Sign in
        </button>
      </div>
    </div>
  )
}

function useQuery<T>(query: string, variables: Record<string, unknown>, deps: unknown[]) {
  const [data, setData] = useState<T | null>(null)
  const [error, setError] = useState<string | null>(null)
  useEffect(() => {
    let active = true
    const load = () =>
      graphql<T>(query, variables)
        .then((d) => active && setData(d))
        .catch((e: Error) => active && setError(e.message))
    load()
    const id = setInterval(load, 10000)
    return () => {
      active = false
      clearInterval(id)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)
  return { data, error }
}

function ErrorNote({ error }: { error: string | null }) {
  if (!error) return null
  return <div className="text-red-600 text-sm">Request failed: {error}</div>
}

function CustomerSearch({ customerId, onOpen }: { customerId: string; onOpen: (id: string) => void }) {
  const { data, error } = useQuery<{ CustomerSearch: { customerId: string; displayName?: string; status?: string; accountCount: number }[] }>(
    `query($customerId: String!){ CustomerSearch(customerId: $customerId){ customerId displayName status accountCount } }`,
    { customerId },
    [customerId],
  )
  const row = data?.CustomerSearch?.[0]
  return (
    <div>
      <h2 className="text-lg font-semibold mb-4">Customer search</h2>
      <ErrorNote error={error} />
      {row ? (
        <div className="bg-white rounded shadow p-4">
          <p><span className="font-medium">Customer:</span> {row.customerId}</p>
          <p><span className="font-medium">Name:</span> {row.displayName}</p>
          <p><span className="font-medium">Status:</span> {row.status}</p>
          <p><span className="font-medium">In-scope accounts:</span> {row.accountCount}</p>
          <button onClick={() => onOpen(row.customerId)} className="mt-3 bg-blue-600 text-white px-4 py-2 rounded">
            Open this customer
          </button>
        </div>
      ) : (
        !error && <p className="text-gray-500">No customer found for id {customerId}.</p>
      )}
    </div>
  )
}

function MonthOverview({ customerId, month }: { customerId: string; month: string }) {
  const { data, error } = useQuery<{
    MonthOverview: { income: number; spending: number; net: number; savingsRate?: number; isPartialMonth: boolean }[]
    DailySpending: { date: string; spending: number }[]
  }>(
    `query($customerId: String!, $month: String!){ MonthOverview(customerId: $customerId, month: $month){ income spending net savingsRate isPartialMonth } DailySpending(customerId: $customerId, month: $month){ date spending } }`,
    { customerId, month },
    [customerId, month],
  )
  const o = data?.MonthOverview?.[0]
  const daily = (data?.DailySpending ?? []).map((d) => ({ ...d, date: d.date.slice(0, 10) }))
  return (
    <div>
      <h2 className="text-lg font-semibold mb-4">Month overview {o?.isPartialMonth ? '(month so far)' : ''}</h2>
      <ErrorNote error={error} />
      {o && (
        <div className="grid grid-cols-4 gap-4 mb-6">
          <Stat label="Money in" value={money(o.income)} />
          <Stat label="Money out" value={money(o.spending)} />
          <Stat label="What is left" value={money(o.net)} />
          <Stat label="Share of income left" value={o.savingsRate == null ? '—' : `${(o.savingsRate * 100).toFixed(1)}%`} />
        </div>
      )}
      <div className="bg-white rounded shadow p-4">
        <h3 className="font-medium mb-3">Daily spending</h3>
        <ResponsiveContainer width="100%" height={250}>
          <LineChart data={daily}>
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Line type="monotone" dataKey="spending" stroke="#2563eb" connectNulls={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-white rounded shadow p-4">
      <p className="text-sm text-gray-500">{label}</p>
      <p className="text-xl font-semibold">{value}</p>
    </div>
  )
}

function Categories({ customerId, month }: { customerId: string; month: string }) {
  const { data, error } = useQuery<{
    CategorySpending: {
      category_l1_id: string
      category_l1_name: string
      spend_usd_cents: number
      normal_spend_usd_cents?: number
      is_much_more_than_usual?: boolean
      children: { category_l2_id: string; category_l2_name: string; spend_usd_cents: number }[]
    }[]
  }>(
    `query($customerId: String!, $month: String!){ CategorySpending(customerId: $customerId, month: $month){ category_l1_id category_l1_name spend_usd_cents normal_spend_usd_cents is_much_more_than_usual children{ category_l2_id category_l2_name spend_usd_cents } } }`,
    { customerId, month },
    [customerId, month],
  )
  return (
    <div>
      <h2 className="text-lg font-semibold mb-4">Categories</h2>
      <ErrorNote error={error} />
      <div className="space-y-3">
        {(data?.CategorySpending ?? []).map((c) => (
          <details key={c.category_l1_id} className="bg-white rounded shadow p-4">
            <summary className="cursor-pointer font-medium flex justify-between">
              <span>{c.category_l1_name}</span>
              <span>
                {money(c.spend_usd_cents)}
                {c.is_much_more_than_usual && <span className="ml-2 text-xs text-red-600">much more than usual</span>}
              </span>
            </summary>
            <ul className="mt-3 pl-4 space-y-1">
              {c.children.map((l2) => (
                <li key={l2.category_l2_id} className="flex justify-between">
                  <span>{l2.category_l2_name}</span>
                  <span>{money(l2.spend_usd_cents)}</span>
                </li>
              ))}
            </ul>
          </details>
        ))}
      </div>
    </div>
  )
}

function Recurring({ customerId }: { customerId: string }) {
  const { data, error } = useQuery<{
    RecurringPayments: {
      recurringPaymentId: string
      merchantName?: string
      frequency?: string
      monthlyCost: number
      becameMoreExpensive: boolean
      status?: string
    }[]
    RecurringTotal: { totalMonthlyCost: number }[]
  }>(
    `query($customerId: String!){ RecurringPayments(customerId: $customerId){ recurringPaymentId merchantName frequency monthlyCost becameMoreExpensive status } RecurringTotal(customerId: $customerId){ totalMonthlyCost } }`,
    { customerId },
    [customerId],
  )
  const total = data?.RecurringTotal?.[0]?.totalMonthlyCost
  return (
    <div>
      <h2 className="text-lg font-semibold mb-4">Recurring payments</h2>
      <ErrorNote error={error} />
      {total != null && <p className="mb-4"><span className="font-medium">Total monthly cost:</span> {money(total)}</p>}
      <table className="w-full bg-white rounded shadow">
        <thead>
          <tr className="text-left border-b">
            <th className="p-2">Merchant</th>
            <th className="p-2">Frequency</th>
            <th className="p-2">Monthly cost</th>
            <th className="p-2">Status</th>
          </tr>
        </thead>
        <tbody>
          {(data?.RecurringPayments ?? []).map((r) => (
            <tr key={r.recurringPaymentId} className="border-b">
              <td className="p-2">
                {r.merchantName}
                {r.becameMoreExpensive && <span className="ml-2 text-xs text-red-600">more expensive</span>}
              </td>
              <td className="p-2">{r.frequency}</td>
              <td className="p-2">{money(r.monthlyCost)}</td>
              <td className="p-2">{r.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function Purchases({ customerId }: { customerId: string }) {
  const { data, error } = useQuery<{
    LargePurchases: {
      transactionId: string
      date: string
      merchantName?: string
      categoryName?: string
      amount: number
      baselineMean: number
      ratio: number
    }[]
  }>(
    `query($customerId: String!){ LargePurchases(customerId: $customerId){ transactionId date merchantName categoryName amount baselineMean ratio } }`,
    { customerId },
    [customerId],
  )
  return (
    <div>
      <h2 className="text-lg font-semibold mb-4">Large purchases</h2>
      <ErrorNote error={error} />
      <table className="w-full bg-white rounded shadow">
        <thead>
          <tr className="text-left border-b">
            <th className="p-2">Date</th>
            <th className="p-2">Merchant</th>
            <th className="p-2">Category</th>
            <th className="p-2">Amount</th>
            <th className="p-2">Baseline mean</th>
            <th className="p-2">Ratio</th>
          </tr>
        </thead>
        <tbody>
          {(data?.LargePurchases ?? []).map((p) => (
            <tr key={p.transactionId} className="border-b">
              <td className="p-2">{p.date}</td>
              <td className="p-2">{p.merchantName}</td>
              <td className="p-2">{p.categoryName}</td>
              <td className="p-2">{money(p.amount)}</td>
              <td className="p-2">{money(p.baselineMean)}</td>
              <td className="p-2">{p.ratio.toFixed(2)}×</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export default App
