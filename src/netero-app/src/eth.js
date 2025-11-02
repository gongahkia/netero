import Web3 from 'web3'

let web3Instance = null

export async function initWeb3() {
  if (web3Instance) return web3Instance
  if (window.ethereum) {
    web3Instance = new Web3(window.ethereum)
    await window.ethereum.request({ method: 'eth_requestAccounts' })
  } else if (window.web3) {
    web3Instance = new Web3(window.web3.currentProvider)
  } else {
    throw new Error('No Ethereum provider detected. Install MetaMask.')
  }
  return web3Instance
}

export async function getAccounts() {
  const web3 = await initWeb3()
  return web3.eth.getAccounts()
}

export async function getNetworkId() {
  const web3 = await initWeb3()
  return web3.eth.net.getId()
}

export async function getDeployedAddress(artifact) {
  const networkId = await getNetworkId()
  const deployed = artifact.networks?.[networkId]
  if (!deployed) throw new Error('Contract not deployed on current network')
  return deployed.address
}

export async function getContract(artifact, address) {
  const web3 = await initWeb3()
  return new web3.eth.Contract(artifact.abi, address)
}

// Optional: try a WebSocket connection to local Ganache for event subscriptions
let web3Ws = null
export function getWeb3WsOptional() {
  try {
    if (web3Ws) return web3Ws
    // Only attempt on localhost to avoid mixed-content issues in production
    if (location.hostname === 'localhost' || location.hostname === '127.0.0.1') {
      // eslint-disable-next-line no-undef
      web3Ws = new Web3(new Web3.providers.WebsocketProvider('ws://127.0.0.1:8545'))
      return web3Ws
    }
  } catch (e) {
    console.warn('WS provider not available:', e)
  }
  return null
}

export function subscribeToEventOptional(abi, address, eventName, handler) {
  const w3 = getWeb3WsOptional()
  if (!w3) return null
  try {
    const c = new w3.eth.Contract(abi, address)
    const sub = c.events[eventName]({}, (err, ev) => {
      if (err) console.error('Event subscription error', err)
      else handler(ev)
    })
    return sub
  } catch (e) {
    console.warn('Event subscription failed, falling back to polling', e)
    return null
  }
}
