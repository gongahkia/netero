# Docker Setup Guide

## Overview

Netero is fully containerized using Docker Compose, making it easy to run on any device with Docker installed.

## Prerequisites

- Docker Desktop (or Docker Engine + Docker Compose)
- At least 4GB of available RAM
- Ports 8080 and 8545 available

## Architecture

The application consists of two main services:

1. **Ganache** (Ethereum blockchain simulator)
   - Port: 8545
   - Chain ID: 1337
   - Pre-funded test accounts with 1000 ETH each
   - Automatically deploys smart contracts on startup

2. **Frontend** (Vue.js web application)
   - Port: 8080
   - Development server with hot-reload
   - Connects to Ganache for blockchain interaction

## Quick Start

### Option 1: Using the helper script

```bash
./docker-start.sh
```

This script will:
- Stop any existing containers
- Build and start all services
- Show you the logs

### Option 2: Manual Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## Running on Another Device

1. **Clone the repository** (or copy the entire project folder)

2. **Install Docker Desktop**
   - macOS: https://www.docker.com/products/docker-desktop/
   - Windows: https://www.docker.com/products/docker-desktop/
   - Linux: https://docs.docker.com/engine/install/

3. **Start Docker Desktop** and ensure it's running

4. **Navigate to the project directory**
   ```bash
   cd path/to/netero
   ```

5. **Run the application**
   ```bash
   docker-compose up -d
   ```

6. **Access the application**
   - Frontend: http://localhost:8080
   - Ganache RPC: http://localhost:8545

## MetaMask Configuration

To interact with the local blockchain:

1. Open MetaMask
2. Add a custom network:
   - Network Name: Netero Local
   - RPC URL: http://localhost:8545
   - Chain ID: 1337
   - Currency Symbol: ETH

3. Import a test account using one of the private keys shown in Ganache logs:
   ```bash
   docker logs netero-ganache | grep "Private Key"
   ```

## Useful Commands

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker logs netero-frontend -f
docker logs netero-ganache -f
```

### Restart services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart frontend
docker-compose restart ganache
```

### Rebuild after code changes

```bash
docker-compose down
docker-compose up -d --build
```

### Clean slate (remove all data)

```bash
docker-compose down -v
docker-compose up -d
```

## File Structure

The Docker setup maintains the same workspace structure:

```
/workspace/
├── netero-app/          # Frontend Vue.js application
└── core/
    └── build/
        └── contracts/   # Compiled smart contract artifacts
```

## Troubleshooting

### Port already in use

If you see "port is already allocated":

```bash
# macOS/Linux
lsof -ti:8080 | xargs kill -9
lsof -ti:8545 | xargs kill -9

# Or change ports in docker-compose.yml
```

### Contracts not found

If the frontend can't find contract artifacts:

```bash
# Rebuild Ganache to recompile contracts
docker-compose restart ganache
```

### Frontend won't start

```bash
# Clear node_modules and reinstall
docker-compose down
docker volume prune -f
docker-compose up -d
```

### Ganache won't deploy contracts

Check the logs for compilation errors:

```bash
docker logs netero-ganache 2>&1 | grep -i error
```

## Development Workflow

1. **Make code changes** in your local `src/` directory
2. **Frontend changes**: Hot-reload automatically (no restart needed)
3. **Contract changes**: 
   ```bash
   docker-compose restart ganache
   docker-compose restart frontend
   ```

## Production Deployment

For production deployment, you should:

1. Update `docker-compose.yml` to use production builds
2. Set proper environment variables (RPC endpoints, contract addresses)
3. Use a reverse proxy (nginx) for SSL/TLS
4. Connect to a real Ethereum network (not Ganache)

## Resource Usage

- **Ganache**: ~200MB RAM, minimal CPU
- **Frontend**: ~300MB RAM, moderate CPU during builds
- **Total**: ~500MB RAM, ~1GB disk space

## Support

If you encounter issues:

1. Check Docker Desktop is running
2. Ensure ports 8080 and 8545 are free
3. Review logs with `docker-compose logs -f`
4. Try a clean rebuild: `docker-compose down -v && docker-compose up -d`
