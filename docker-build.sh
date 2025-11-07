#!/bin/bash

# Pre-build script for Docker
# Compiles contracts locally before Docker build

set -e

echo "🔨 Pre-build: Compiling smart contracts..."

cd src/core

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing contract dependencies..."
    npm install
fi

# Compile contracts
echo "⚙️  Compiling contracts with Truffle..."
npx truffle compile

echo "✅ Smart contracts compiled successfully!"
echo ""
echo "📦 Build artifacts ready in src/core/build/"
echo ""
echo "🐳 Ready for Docker build. Run:"
echo "   docker-compose up --build"
