#!/usr/bin/env node
const fs = require('fs')
const path = require('path')

const root = __dirname
const subgraphYamlPath = path.join(root, '..', 'subgraph.yaml')
const artifactPath = path.join(root, '..', '..', '..', 'core', 'build', 'contracts', 'PollFactory.json')

function getAddressFromArtifact() {
  const envAddress = process.env.ADDRESS || process.argv[2]
  if (envAddress && /^0x[a-fA-F0-9]{40}$/.test(envAddress)) {
    return envAddress
  }
  const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'))
  const networks = artifact.networks || {}
  const ids = Object.keys(networks)
  if (!ids.length) {
    throw new Error('No networks found in PollFactory artifact. Migrate contracts first or pass ADDRESS explicitly.')
  }
  const first = networks[ids[0]]
  if (!first.address) {
    throw new Error('No address found in networks entry in PollFactory artifact.')
  }
  return first.address
}

function main() {
  const addr = getAddressFromArtifact()
  let text = fs.readFileSync(subgraphYamlPath, 'utf8')
  // Try to replace existing address line keeping indentation
  const replaced = text.replace(/^(\s*)address:\s*"0x[^"]*".*$/m, (m, indent) => `${indent}address: "${addr}"`)
  if (replaced !== text) {
    fs.writeFileSync(subgraphYamlPath, replaced)
    console.log(`Updated address in subgraph.yaml to ${addr}`)
    return
  }
  // If address line not present (or file malformed), try to insert under 'source:'
  const srcIdx = text.indexOf('\n    source:')
  if (srcIdx >= 0) {
    const insertAt = srcIdx + '\n    source:'.length
    const fixed = text.slice(0, insertAt) + `\n      address: "${addr}"` + text.slice(insertAt)
    fs.writeFileSync(subgraphYamlPath, fixed)
    console.log(`Inserted address in subgraph.yaml to ${addr}`)
    return
  }
  throw new Error('Could not locate source: block to set address')
}

main()
