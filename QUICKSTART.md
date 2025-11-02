# Netero Quick Start Guide

## Prerequisites

Before running Netero, ensure you have the following installed:

- **Node.js** (v14 or later)
- **npm** (comes with Node.js)
- **MetaMask** browser extension ([Installation links in README](README.md#usage))

## Running the Project

### Option 1: Automated Startup (Recommended) ⚡

**For WSL/Linux/Mac:**
```bash
./start.sh
```

**For Windows:**
```cmd
start.bat
```

This will automatically:
1. Install frontend dependencies (if needed)
2. Start Ganache blockchain on http://localhost:8545
3. Deploy smart contracts
4. Start Vue.js frontend on http://localhost:8080

**To stop:** Press `Ctrl+C` (bash) or close the terminal windows (Windows batch)

---

### Option 2: Manual Startup 🔧

If you prefer to run services separately:

#### Terminal 1 - Start Ganache:
```bash
cd src/core
npx ganache --server.port 8545 --chain.chainId 1337
```

#### Terminal 2 - Deploy Smart Contracts:
```bash
cd src/core
npx truffle migrate --network development
```

#### Terminal 3 - Start Frontend:
```bash
cd src/netero-app
npm install  # first time only
npm run serve
```

---

## MetaMask Configuration

After starting Ganache, configure MetaMask with these settings:

- **Network Name:** Netero Local (or any name)
- **New RPC URL:** http://localhost:8545
- **Chain ID:** 1337
- **Currency Symbol:** ETH

### Import Test Account

Copy one of the private keys from the Ganache output and import it into MetaMask for testing. Each test account has 1000 ETH.

---

## Accessing the Application

Once all services are running:

- **Frontend:** http://localhost:8080
- **Ganache RPC:** http://localhost:8545

---

## Troubleshooting

### Ganache fails to start
- **Error:** Port 8545 already in use
  - **Solution:** Kill the existing process: `lsof -ti:8545 | xargs kill -9`

### Smart contract deployment fails
- **Error:** Network not available
  - **Solution:** Ensure Ganache is running first

### MetaMask not connecting
- **Error:** Cannot connect to network
  - **Solution:** Check that Chain ID is 1337 and RPC URL is http://localhost:8545

### Frontend won't start
- **Error:** npm dependencies missing
  - **Solution:** Run `npm install` in `src/netero-app/`

---

## Log Files

When using the orchestration scripts, logs are saved to:
- `logs/ganache.log` - Blockchain output
- `logs/truffle.log` - Smart contract deployment
- `logs/vue.log` - Frontend server output

View logs in real-time:
```bash
tail -f logs/ganache.log
tail -f logs/vue.log
```

---

## Project Structure

```
netero/
├── start.sh              # Bash orchestration script
├── start.bat             # Windows orchestration script
├── src/
│   ├── main.py          # Legacy Python backend (deprecated)
│   ├── core/            # Smart contract layer
│   │   ├── contracts/   # Solidity contracts
│   │   ├── migrations/  # Truffle deployment scripts
│   │   └── truffle-config.js
│   └── netero-app/      # Vue.js frontend
│       ├── src/
│       │   ├── App.vue
│       │   └── components/
│       └── package.json
└── logs/                # Runtime logs (auto-created)
```

---

## Development Workflow

1. Start services with orchestration script
2. Make changes to Vue components or Smart contracts
3. Smart contract changes require re-running `truffle migrate`
4. Vue.js changes auto-reload (hot module replacement)
5. Stop all services with Ctrl+C

Happy voting! 🗳️
