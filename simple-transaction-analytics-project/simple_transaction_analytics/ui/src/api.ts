// Minimal GraphQL client for the Spending Insights API.
// The API URL is configurable; defaults to the local DataSQRL server.

export const API_URL =
  import.meta.env.VITE_API_URL ?? 'http://localhost:8888/v1/graphql'

export function setToken(token: string | null) {
  if (token) {
    localStorage.setItem('spending-insights-token', token)
  } else {
    localStorage.removeItem('spending-insights-token')
  }
}

export function getToken(): string | null {
  return localStorage.getItem('spending-insights-token')
}

export async function graphql<T>(query: string, variables: Record<string, unknown>): Promise<T> {
  const token = getToken()
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({ query, variables }),
  })
  const json = await res.json()
  if (json.errors?.length) {
    throw new Error(json.errors.map((e: { message: string }) => e.message).join('; '))
  }
  return json.data as T
}
