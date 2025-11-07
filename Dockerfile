# Multi-stage Dockerfile for Netero
# Simplified approach: compile contracts locally, then copy into container

# Stage 1: Build Vue.js frontend
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend
COPY src/netero-app/package*.json ./
RUN npm ci

COPY src/netero-app/ ./
COPY src/core/build ./build/contracts

RUN npm run build

# Stage 2: Runtime - Python backend + Ganache + frontend
FROM python:3.11-slim

# Install Node.js for Ganache
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

# Copy smart contracts source and build artifacts
COPY src/core ./src/core

# Copy Python backend
COPY src/main.py ./src/

# Copy built frontend
COPY --from=frontend-builder /app/frontend/dist ./src/netero-app/dist

# Copy start script
COPY start.sh ./

# Expose ports
# 8545: Ganache RPC
# 8080: Vue.js frontend
EXPOSE 8545 8080

# Set working directory to src for main.py
WORKDIR /app/src

# Default command: start Ganache and deploy contracts
CMD ["python3", "main.py"]
