# 🚀 Netero Docker - Quick Start Guide

## ✅ All Features Successfully Implemented

All requested features have been implemented and tested:

1. **📊 Subgraph-backed Org Overview Chart** - Analytics showing votes over time
2. **⚡ Gasless Enabled Badge** - Visual indicator for meta-transaction support
3. **🔐 Enhanced Commit-Reveal UX** - Copy salt button + encrypted backup/restore
4. **🐳 Full Docker Support** - Complete containerization with one-command deployment

## 🎯 Quick Start (3 Steps)

### Step 1: Compile Smart Contracts

```bash
cd netero
./docker-start.sh compile
```

### Step 2: Start Docker Containers

```bash
docker-compose up --build -d
```

### Step 3: Access the Application

- **Frontend**: http://localhost:8080
- **Ganache RPC**: http://localhost:8545
- **Chain ID**: Auto-generated (check with `curl -X POST http://localhost:8545 -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}'`)

## 📋 What's Running

```bash
# Check container status
docker-compose ps

# Check logs
docker logs netero-ganache
docker logs netero-frontend

# Test Ganache RPC
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}'
```

## 🔧 Configure MetaMask

1. Open MetaMask browser extension
2. Add Custom Network:
   - **Network Name**: Netero Local
   - **RPC URL**: http://localhost:8545
   - **Chain ID**: (get from net_version RPC call above)
   - **Currency Symbol**: ETH

3. Import Account (use any Ganache private key):
   ```bash
   # Get account details from Ganache logs
   docker logs netero-ganache | grep "Private Keys"
   ```

## 🎨 Features to Try

### 1. Organization Dashboard
- Create polls with various settings
- Enable gasless voting (trustedForwarder)
- View the Org Overview Chart (requires subgraph)

### 2. Voting Interface  
- Test commit-reveal voting:
  - Commit your vote
  - Copy the salt with one click
  - Download encrypted backup
  - Import backup to restore

### 3. Results Display
- Real-time vote tallies
- Doughnut chart visualization
- Poll state management (Activate/End/Finalize)

## 🛠 Troubleshooting

### Containers Won't Start

```bash
# Clean rebuild
docker-compose down -v
./docker-start.sh compile
docker-compose up --build
```

### Port Already in Use

```bash
# Find what's using the port
lsof -i :8545  # or :8080

# Change ports in docker-compose.yml if needed
```

### Frontend Not Loading

```bash
# Check logs
docker logs netero-frontend

# Verify contracts are mounted
docker exec netero-frontend ls -la /app/core/build/contracts
```

### Ganache Not Accessible

```bash
# Test from inside container
docker exec netero-ganache sh -c "curl -X POST http://127.0.0.1:8545 -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"net_version\",\"params\":[],\"id\":1}'"

# Test from host
curl -X POST http://localhost:8545 -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}'
```

## 🔄 Development Workflow

### Making Changes

```bash
# 1. Edit code
# 2. Rebuild affected service
docker-compose up --build ganache  # or frontend
```

### Recompile Contracts

```bash
# Compile locally
cd src/core
npx truffle compile

# Rebuild ganache container
docker-compose up --build ganache
```

### View Real-time Logs

```bash
# Follow all logs
docker-compose logs -f

# Follow specific service
docker logs -f netero-ganache
docker logs -f netero-frontend
```

## 📦 With Subgraph Indexer (Optional)

For full analytics features:

```bash
# Start with indexer profile
docker-compose --profile indexer up --build -d

# Services available:
# - Graph Node: http://localhost:8000
# - IPFS: http://localhost:5001
# - PostgreSQL: localhost:5432
```

Then deploy the subgraph:

```bash
# In another terminal
cd src/indexer/subgraph
npm install
npm run codegen
npm run build
npm run create-local
npm run deploy-local
```

## 🌟 Production Deployment

For production use:

1. Change RPC URL from localhost to your server IP
2. Update `truffle-config.js` networks
3. Use environment variables for sensitive data
4. Enable HTTPS with nginx/traefik
5. Set up proper Ethereum node (not Ganache)

## 📚 More Documentation

- **Complete Features**: See [FEATURES.md](FEATURES.md)
- **Docker Details**: See [DOCKER.md](DOCKER.md) (comprehensive guide)
- **Implementation**: See [IMPLEMENTATION.md](IMPLEMENTATION.md)

## ✅ Verification Checklist

- [ ] Containers running: `docker-compose ps`
- [ ] Ganache accessible: `curl localhost:8545`
- [ ] Frontend accessible: `curl localhost:8080`
- [ ] MetaMask connected to local network
- [ ] Can create a poll
- [ ] Can vote on a poll
- [ ] Gasless badge appears (when trustedForwarder set)
- [ ] Commit-reveal copy salt works
- [ ] Backup download/import works

## 🆘 Getting Help

If you encounter issues:

1. Check container logs: `docker-compose logs`
2. Verify contracts compiled: `ls src/core/build/contracts/`
3. Check browser console for frontend errors
4. Ensure Docker Desktop is running
5. Try clean rebuild: `docker-compose down -v && ./docker-start.sh`

---

**🎉 You're all set!** Visit http://localhost:8080 and start voting!
