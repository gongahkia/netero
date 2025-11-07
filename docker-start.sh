#!/bin/bash

# Docker Build and Run Helper for Netero
# This script compiles contracts and starts Docker services

set -e

echo "🚀 Netero Docker Build Helper"
echo "=============================="
echo ""

# Function to compile contracts
compile_contracts() {
    echo "🔨 Step 1: Compiling smart contracts..."
    cd src/core
    
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing contract dependencies..."
        npm install
    fi
    
    echo "⚙️  Compiling with Truffle..."
    npx truffle compile
    
    cd ../..
    echo "✅ Contracts compiled!"
    echo ""
}

# Function to start Docker
start_docker() {
    local profile=$1
    
    echo "🐳 Step 2: Starting Docker services..."
    
    if [ "$profile" == "indexer" ]; then
        echo "📊 Starting with Graph Node indexer..."
        docker-compose --profile indexer up --build
    else
        echo "🔧 Starting basic setup (Ganache + Frontend)..."
        docker-compose up --build
    fi
}

# Main execution
case "$1" in
    "indexer")
        echo "Mode: Full setup with indexer"
        echo ""
        compile_contracts
        start_docker "indexer"
        ;;
    "compile")
        echo "Mode: Compile contracts only"
        echo ""
        compile_contracts
        echo "✅ Done! Now run: docker-compose up --build"
        ;;
    *)
        echo "Mode: Basic setup (Ganache + Frontend)"
        echo ""
        compile_contracts
        start_docker "basic"
        ;;
esac
