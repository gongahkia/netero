#!/usr/bin/env node
const fs = require('fs')
const path = require('path')
const yaml = require('js-yaml')

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
  const doc = yaml.load(fs.readFileSync(subgraphYamlPath, 'utf8'))
  if (!doc || !doc.dataSources || !doc.dataSources.length) {
    throw new Error('Malformed subgraph.yaml: no dataSources')
  }
  doc.dataSources[0].source.address = addr
  const out = yaml.dump(doc, { noRefs: true, lineWidth: -1 })
  fs.writeFileSync(subgraphYamlPath, out)
  console.log(`Updated subgraph.yaml dataSources[0].source.address to ${addr}`)
}

main()
