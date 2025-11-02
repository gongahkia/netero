Netero Subgraph (The Graph)

This subgraph indexes PollFactory and Poll contracts to power fast queries and analytics.

What it indexes
- PollFactory: PollCreated(org, creator, poll, title) → creates Org and Poll entities
- Poll: Voted(voter, optionIndex), StateChanged(oldState, newState)

Folder layout
- schema.graphql: entity schema for Org, Poll, Vote
- subgraph.yaml: data sources (PollFactory) and template (Poll)
- src/mapping-factory.ts: handles PollCreated
- src/mapping-poll.ts: handles Voted and StateChanged

Prereqs
- graph-node running locally (docker-compose with IPFS and Postgres)
- graph-cli installed (npm i)
- Truffle migration already run so PollFactory is deployed; update the address in subgraph.yaml

Quick start (local graph-node)
1) Install deps
   npm install
2) Set PollFactory address in subgraph.yaml
   - Replace the dummy address with the address from src/core/build/contracts/PollFactory.json for network development.
3) Generate and build
   npm run codegen
   npm run build
4) Create and deploy (local)
   npm run create-local
   npm run deploy-local

Notes
- For Ganache, use network: localhost in subgraph.yaml.
- The mapping imports use generated types paths (../generated/*) produced by `graph codegen`.
- If you change the schema or ABI, re-run `codegen` and `build`.
