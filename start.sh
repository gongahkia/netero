#!/bin/bash

# Netero - Orchestration Script
# Starts both backend (Ganache + Smart Contracts) and frontend (Vue.js)

set -e  # Exit on error

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function to print colored messages
print_status() {
    echo -e "${BLUE}[NETERO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Cleanup function
cleanup() {
    print_warning "Shutting down services..."
    kill 0  # Kill all processes in the current process group
    exit
}

# Trap SIGINT (Ctrl+C) and cleanup
trap cleanup SIGINT SIGTERM

# Check if node is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm first."
    exit 1
fi

# Check if python3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

print_status "Starting Netero..."
echo ""

# Ensure log directory is available before redirecting
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

# Step 1: Install dependencies if needed
if [ ! -d "src/netero-app/node_modules" ]; then
    print_status "Installing frontend dependencies..."
    cd src/netero-app
    npm install
    cd ../..
    print_success "Frontend dependencies installed"
else
    print_success "Frontend dependencies already installed"
fi

# Check if truffle and ganache are available
if ! npm list -g ganache &> /dev/null && ! npm list ganache &> /dev/null; then
    print_warning "Ganache not found. Installing globally..."
    npm install -g ganache
fi

if ! npm list -g truffle &> /dev/null && ! npm list truffle &> /dev/null; then
    print_warning "Truffle not found. Installing globally..."
    npm install -g truffle
fi

# Step 2: Start Ganache in the background
print_status "Starting Ganache (local blockchain)..."
cd src/core
if [ -f package.json ]; then
    print_status "Installing core (solidity) dependencies..."
    npm ci > ../../$LOG_DIR/core-npm.log 2>&1 || npm install > ../../$LOG_DIR/core-npm.log 2>&1 || true
fi
npx ganache --server.port 8545 --chain.chainId 1337 > ../../$LOG_DIR/ganache.log 2>&1 &
GANACHE_PID=$!
cd ../..

# Wait for Ganache to start
print_status "Waiting for Ganache to initialize..."
sleep 5

# Check if Ganache is running
if ps -p $GANACHE_PID > /dev/null; then
    print_success "Ganache started successfully on http://localhost:8545"
else
    print_error "Ganache failed to start. Check logs/ganache.log for details."
    exit 1
fi

# Step 3: Deploy smart contracts
print_status "Deploying smart contracts with Truffle..."
cd src/core
npx truffle migrate --network development > ../../$LOG_DIR/truffle.log 2>&1
MIGRATE_STATUS=$?
cd ../..

if [ $MIGRATE_STATUS -eq 0 ]; then
    print_success "Smart contracts deployed successfully"
else
    print_error "Smart contract deployment failed. Check logs/truffle.log for details."
    kill $GANACHE_PID
    exit 1
fi

# Optional Step 4: Bring up local Graph indexer and deploy subgraph (can skip with NETERO_SKIP_INDEXER=1)
if [ -z "${NETERO_SKIP_INDEXER}" ]; then
    print_status "Starting local Graph indexer (docker compose)…"
    (
        cd src/indexer
        docker compose up -d > ../../$LOG_DIR/indexer.log 2>&1
    )
    print_status "Waiting for Graph Node to become ready…"
    # Wait for Admin API (8020) and GraphQL (8000)
    START_TS=$(date +%s)
    TIMEOUT=120
    until curl -sf -o /dev/null http://127.0.0.1:8020/ && curl -sf -o /dev/null http://127.0.0.1:8000/health; do
        sleep 2
        NOW=$(date +%s)
        if [ $((NOW-START_TS)) -ge $TIMEOUT ]; then
            print_warning "Graph services not healthy yet. Continuing anyway."
            break
        fi
    done

    print_status "Deploying subgraph…"
    (
        cd src/indexer/subgraph
        # Install CLI if needed (local devDependency)
        npm ci > ../../../$LOG_DIR/subgraph-npm.log 2>&1 || npm install > ../../../$LOG_DIR/subgraph-npm.log 2>&1
        # Set factory address from Truffle artifact
        npm run set-address > ../../../$LOG_DIR/subgraph.log 2>&1 || true
        # Build and deploy
        npx graph codegen >> ../../../$LOG_DIR/subgraph.log 2>&1
        npx graph build >> ../../../$LOG_DIR/subgraph.log 2>&1
        # create can fail if exists; ignore error
        npx graph create --node http://127.0.0.1:8020 netero/subgraph >> ../../../$LOG_DIR/subgraph.log 2>&1 || true
        npx graph deploy --node http://127.0.0.1:8020 --ipfs http://127.0.0.1:5001 netero/subgraph >> ../../../$LOG_DIR/subgraph.log 2>&1 || true
    )
    print_success "Subgraph deployed (check http://127.0.0.1:8000/subgraphs/name/netero/subgraph)"
else
    print_status "Skipping indexer startup and subgraph deployment (NETERO_SKIP_INDEXER=1)"
fi

# Step 5: Start Vue.js frontend
print_status "Starting Vue.js frontend..."
cd src/netero-app
npm run serve > ../../$LOG_DIR/vue.log 2>&1 &
VUE_PID=$!
cd ../..

# Wait for Vue.js to start
print_status "Waiting for Vue.js to initialize..."
sleep 5

# Check if Vue.js is running
if ps -p $VUE_PID > /dev/null; then
    print_success "Vue.js frontend started successfully"
else
    print_error "Vue.js frontend failed to start. Check logs/vue.log for details."
    kill $GANACHE_PID
    exit 1
fi

echo ""
echo "=========================================="
print_success "Netero is now running!"
echo "=========================================="
echo ""
echo -e "${GREEN}Frontend:${NC} http://localhost:8080"
echo -e "${GREEN}Ganache:${NC}  http://localhost:8545"
echo ""
print_status "Press Ctrl+C to stop all services"
echo ""

# Keep the script running and show logs
tail -f "$LOG_DIR/vue.log"
