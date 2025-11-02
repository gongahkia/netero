export async function graphqlRequest(endpoint, query, variables = {}) {
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, variables })
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`GraphQL error: ${res.status} ${text}`)
  }
  const body = await res.json()
  if (body.errors) {
    throw new Error(`GraphQL errors: ${JSON.stringify(body.errors)}`)
  }
  return body.data
}
