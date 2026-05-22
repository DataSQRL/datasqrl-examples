import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { Client, Provider, cacheExchange, fetchExchange } from 'urql'
import './index.css'
import App from './App.jsx'

const client = new Client({
  url: import.meta.env.VITE_GRAPHQL_URL || 'http://localhost:8888/v1/graphql',
  exchanges: [cacheExchange, fetchExchange],
})

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <Provider value={client}>
      <App />
    </Provider>
  </StrictMode>,
)
