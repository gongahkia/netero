#!/bin/bash

# Simple Netero Startup Script
# This version provides clearer output and better error handling

set -e

echo "🚀 Starting Netero Blockchain Voting Platform"
echo ""

# Create logs directory
mkdir -p logs

# Install frontend dependencies if needed
if [ ! -d "src/netero-app/node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    cd src/netero-app && npm install && cd ../..
    echo "✅ Dependencies installed"
else
    echo "✅ Dependencies already installed"
fi

echo ""
echo "🔗 Starting Ganache blockchain..."
cd src/core
npx ganache --server.port 8545 --chain.chainId 1337 > ../../logs/ganache.log 2>&1 &
GANACHE_PID=$!
cd ../..

echo "⏳ Waiting for Ganache..."
sleep 5

if ! ps -p $GANACHE_PID > /dev/null; then
    echo "❌ Ganache failed to start"
    echo "Check logs/ganache.log for details"
    exit 1
fi

echo "✅ Ganache running on http://localhost:8545"
echo ""

echo "📝 Deploying smart contracts..."
cd src/core
if npx truffle migrate --network development > ../../logs/truffle.log 2>&1; then
    echo "✅ Smart contracts deployed"
else
    echo "❌ Deployment failed. Check logs/truffle.log"
    kill $GANACHE_PID
    cd ../..
    exit 1
fi
cd ../..

echo ""
echo "🎨 Starting Vue.js frontend..."
cd src/netero-app
npm run serve > ../../logs/vue.log 2>&1 &
VUE_PID=$!
cd ../..

echo "⏳ Waiting for Vue.js..."
sleep 5

if ! ps -p $VUE_PID > /dev/null; then
    echo "❌ Vue.js failed to start"
    echo "Check logs/vue.log for details"
    kill $GANACHE_PID
    exit 1
fi

echo "✅ Frontend running on http://localhost:8080"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Netero is ready!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Frontend:  http://localhost:8080"
echo "⛓️  Blockchain: http://localhost:8545"
echo ""
echo "📋 View logs:"
echo "   tail -f logs/ganache.log"
echo "   tail -f logs/vue.log"
echo ""
echo "🛑 Press Ctrl+C to stop all services"
echo ""

# Cleanup on exit
trap "echo '' && echo '🛑 Stopping services...' && kill $GANACHE_PID $VUE_PID 2>/dev/null && echo '✅ Shutdown complete' && exit" SIGINT SIGTERM

# Keep running
wait
