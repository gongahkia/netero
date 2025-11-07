# Multi-stage Dockerfile for Netero
# Builds the complete stack: contracts, Vue.js frontend, and backend

# Stage 1: Build smart contracts
FROM node:18-alpine AS contracts-builder

WORKDIR /app/core
COPY src/core/package*.json ./
RUN npm ci --only=production

COPY src/core/ ./
RUN npx truffle compile

# Stage 2: Build Vue.js frontend
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend
COPY src/netero-app/package*.json ./
RUN npm ci

COPY src/netero-app/ ./
# Copy compiled contracts for frontend
COPY --from=contracts-builder /app/core/build ./src/core-build

RUN npm run build

# Stage 3: Build subgraph (optional - for indexer)
FROM node:18-alpine AS subgraph-builder

WORKDIR /app/subgraph
COPY src/indexer/subgraph/package*.json ./
RUN npm ci

COPY src/indexer/subgraph/ ./
COPY --from=contracts-builder /app/core/build/contracts ./contracts

# Stage 4: Runtime - Python backend + Ganache + compiled contracts + frontend
FROM python:3.11-slim

# Install Node.js for Ganache and npm packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
RUN pip install --no-cache-dir web3

# Install global npm packages (ganache, truffle)
RUN npm install -g ganache truffle

# Copy smart contracts and build artifacts
COPY --from=contracts-builder /app/core ./src/core

# Copy Python backend
COPY src/main.py ./src/

# Copy built frontend
COPY --from=frontend-builder /app/frontend/dist ./src/netero-app/dist

# Copy start script
COPY start.sh ./

# Expose ports
# 8545: Ganache RPC
# 8080: Vue.js frontend (served via simple HTTP server)
EXPOSE 8545 8080

# Set working directory to src for main.py
WORKDIR /app/src

# Default command: start Ganache and deploy contracts
CMD ["python3", "main.py"]
