import { useState } from 'react'
import { useQuery } from 'urql'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { format, parseISO } from 'date-fns'
import './App.css'

const SPENDING_BY_CATEGORY_QUERY = `
  query SpendingByCategory($customerId: Long!, $limit: Int) {
    SpendingByCategory(customerId: $customerId, limit: $limit) {
      customerId
      timeWeek
      category
      spending
    }
  }
`

const SPENDING_BY_DAY_QUERY = `
  query SpendingByDay($customerId: Long!, $fromTime: DateTime!, $toTime: DateTime!, $limit: Int) {
    SpendingByDay(customerId: $customerId, fromTime: $fromTime, toTime: $toTime, limit: $limit) {
      timeDay
      spending
    }
  }
`

const TRANSACTIONS_QUERY = `
  query Transactions($customerId: Long!, $fromTime: DateTime!, $toTime: DateTime!, $limit: Int) {
    Transactions(customerId: $customerId, fromTime: $fromTime, toTime: $toTime, limit: $limit) {
      transactionId
      cardNo
      time
      amount
      merchantName
      category
      customerId
    }
  }
`

function SpendingByCategoryChart({ customerId }) {
  const [result] = useQuery({
    query: SPENDING_BY_CATEGORY_QUERY,
    variables: { customerId: parseInt(customerId), limit: 50 },
    pause: !customerId,
  })

  const { data, fetching, error } = result

  if (fetching) return <div className="loading">Loading spending by category...</div>
  if (error) return <div className="error">Error: {error.message}</div>
  if (!data?.SpendingByCategory?.length) return <div className="no-data">No data available</div>

  const categories = [...new Set(data.SpendingByCategory.map(d => d.category))]
  const weeks = [...new Set(data.SpendingByCategory.map(d => d.timeWeek))].sort()

  const chartData = weeks.map(week => {
    const weekData = { week: format(parseISO(week), 'MMM dd') }
    categories.forEach(category => {
      const item = data.SpendingByCategory.find(d => d.timeWeek === week && d.category === category)
      weekData[category] = item ? item.spending : 0
    })
    return weekData
  })

  const colors = ['#117ACA', '#002d72', '#5899DA', '#19A979', '#ED8B00', '#945ECF', '#13A4B4', '#E8743B']

  return (
    <div className="chart-container">
      <h2>Spending by Category (Weekly)</h2>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="week" />
          <YAxis />
          <Tooltip formatter={(value) => `$${value.toFixed(2)}`} />
          <Legend />
          {categories.map((category, idx) => (
            <Line
              key={category}
              type="monotone"
              dataKey={category}
              stroke={colors[idx % colors.length]}
              activeDot={{ r: 8 }}
            />
          ))}
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}

function SpendingByDayChart({ customerId, fromTime, toTime }) {
  const [result] = useQuery({
    query: SPENDING_BY_DAY_QUERY,
    variables: {
      customerId: parseInt(customerId),
      fromTime,
      toTime,
      limit: 100
    },
    pause: !customerId || !fromTime || !toTime,
  })

  const { data, fetching, error } = result

  if (fetching) return <div className="loading">Loading spending by day...</div>
  if (error) return <div className="error">Error: {error.message}</div>
  if (!data?.SpendingByDay?.length) return <div className="no-data">No data available</div>

  const chartData = data.SpendingByDay.map(d => ({
    day: format(parseISO(d.timeDay), 'MMM dd'),
    spending: d.spending
  })).reverse()

  return (
    <div className="chart-container">
      <h2>Spending by Day</h2>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="day" />
          <YAxis />
          <Tooltip formatter={(value) => `$${value.toFixed(2)}`} />
          <Legend />
          <Line type="monotone" dataKey="spending" stroke="#117ACA" strokeWidth={2} activeDot={{ r: 8 }} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}

function TransactionsTable({ customerId, fromTime, toTime }) {
  const [result] = useQuery({
    query: TRANSACTIONS_QUERY,
    variables: {
      customerId: parseInt(customerId),
      fromTime,
      toTime,
      limit: 100
    },
    pause: !customerId || !fromTime || !toTime,
  })

  const { data, fetching, error } = result

  if (fetching) return <div className="loading">Loading transactions...</div>
  if (error) return <div className="error">Error: {error.message}</div>
  if (!data?.Transactions?.length) return <div className="no-data">No transactions available</div>

  return (
    <div className="table-container">
      <h2>Transactions ({data.Transactions.length})</h2>
      <div className="table-wrapper">
        <table className="transactions-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Merchant</th>
              <th>Category</th>
              <th>Amount</th>
              <th>Card No.</th>
              <th>Transaction ID</th>
            </tr>
          </thead>
          <tbody>
            {data.Transactions.map((tx) => (
              <tr key={tx.transactionId}>
                <td>{format(parseISO(tx.time), 'MMM dd, yyyy HH:mm')}</td>
                <td>{tx.merchantName}</td>
                <td><span className="category-badge">{tx.category}</span></td>
                <td className="amount">${tx.amount.toFixed(2)}</td>
                <td>{tx.cardNo}</td>
                <td className="transaction-id">{tx.transactionId}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function App() {
  const [customerId, setCustomerId] = useState('1')
  const [fromTime, setFromTime] = useState('2024-05-05')
  const [toTime, setToTime] = useState('2024-06-05')
  const [activeCustomerId, setActiveCustomerId] = useState('')

  const handleSubmit = (e) => {
    e.preventDefault()
    setActiveCustomerId(customerId)
  }

  const fromTimeFormatted = fromTime ? `${fromTime}T00:00:00Z` : ''
  const toTimeFormatted = toTime ? `${toTime}T00:00:00Z` : ''

  return (
    <div className="app">
      <header className="app-header">
        <h1>
          <span className="chose-logo">CHOSE</span>
          Credit Card Analytics
        </h1>
        <p className="subtitle">Internal Operations Portal</p>
      </header>

      <div className="content">
        <form onSubmit={handleSubmit} className="query-form">
          <div className="form-group">
            <label htmlFor="customerId">Customer ID</label>
            <input
              id="customerId"
              type="number"
              value={customerId}
              onChange={(e) => setCustomerId(e.target.value)}
              placeholder="Enter customer ID"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="fromTime">From Date</label>
            <input
              id="fromTime"
              type="date"
              value={fromTime}
              onChange={(e) => setFromTime(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label htmlFor="toTime">To Date</label>
            <input
              id="toTime"
              type="date"
              value={toTime}
              onChange={(e) => setToTime(e.target.value)}
            />
          </div>

          <button type="submit" className="submit-btn">Load Analytics</button>
        </form>

        {activeCustomerId && (
          <div className="analytics-section">
            <div className="customer-info">
              <h3>Customer #{activeCustomerId}</h3>
              <p>Period: {fromTime} to {toTime}</p>
            </div>

            <SpendingByCategoryChart customerId={activeCustomerId} />
            <SpendingByDayChart
              customerId={activeCustomerId}
              fromTime={fromTimeFormatted}
              toTime={toTimeFormatted}
            />
            <TransactionsTable
              customerId={activeCustomerId}
              fromTime={fromTimeFormatted}
              toTime={toTimeFormatted}
            />
          </div>
        )}

        {!activeCustomerId && (
          <div className="welcome-message">
            <p>Enter a customer ID and date range to view analytics</p>
          </div>
        )}
      </div>
    </div>
  )
}

export default App
