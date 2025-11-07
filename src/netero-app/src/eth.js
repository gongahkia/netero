import Web3 from 'web3'

let web3Instance = null

export function hasInjectedProvider() {
  return typeof window !== 'undefined' && (window.ethereum || window.web3)
}

// Initialize Web3 only if a provider exists. Never throw here —
// callers should handle a null return value gracefully.
export async function initWeb3() {
  if (web3Instance) return web3Instance

  if (hasInjectedProvider()) {
    if (window.ethereum) {
      web3Instance = new Web3(window.ethereum)
      try {
        await window.ethereum.request({ method: 'eth_requestAccounts' })
      } catch (e) {
        // User rejected or request failed — keep instance so read calls still work
        console.warn('eth_requestAccounts was not granted', e)
      }
    } else if (window.web3) {
      web3Instance = new Web3(window.web3.currentProvider)
    }
  } else {
    // No provider available; return null to avoid runtime overlay errors.
    web3Instance = null
  }
  return web3Instance
}

export async function getAccounts() {
  const web3 = await initWeb3()
  if (!web3) return []
  try {
    return await web3.eth.getAccounts()
  } catch (e) {
    console.warn('getAccounts failed', e)
    return []
  }
}

export async function getNetworkId() {
  const web3 = await initWeb3()
  if (!web3) return null
  try {
    return await web3.eth.net.getId()
  } catch (e) {
    console.warn('getNetworkId failed', e)
    return null
  }
}

export async function getChainIdHex() {
  try {
    if (!window?.ethereum) return null
    const id = await window.ethereum.request({ method: 'eth_chainId' })
    return id
  } catch (e) {
    console.warn('getChainIdHex failed', e)
    return null
  }
}

export async function isCorrectNetwork() {
  const chainId = await getChainIdHex()
  // Local Ganache default in this project
  return chainId === '0x539' || chainId === '0x7e0' // 1337 or 2016 (fallback)
}

export async function switchToLocalNetwork() {
  if (!window?.ethereum) return false
  try {
    await window.ethereum.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId: '0x539' }], // 1337
    })
    return true
  } catch (switchError) {
    // If the chain hasn't been added to MetaMask
    if (switchError?.code === 4902) {
      try {
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [
            {
              chainId: '0x539',
              chainName: 'Netero Local 1337',
              nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 },
              rpcUrls: ['http://127.0.0.1:8545'],
            },
          ],
        })
        return true
      } catch (addErr) {
        console.warn('Failed to add local chain', addErr)
        return false
      }
    }
    console.warn('Failed to switch network', switchError)
    return false
  }
}

export async function getDeployedAddress(artifact) {
  const networkId = await getNetworkId()
  if (!networkId) return null
  const deployed = artifact.networks?.[networkId]
  return deployed ? deployed.address : null
}

export async function getContract(artifact, address) {
  const web3 = await initWeb3()
  if (!web3 || !artifact?.abi || !address) return null
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
