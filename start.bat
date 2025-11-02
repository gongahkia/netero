@echo off
REM Netero - Orchestration Script for Windows
REM Starts both backend (Ganache + Smart Contracts) and frontend (Vue.js)

echo [NETERO] Starting Netero...
echo.

REM Check if node is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed. Please install Node.js first.
    exit /b 1
)

REM Check if npm is installed
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] npm is not installed. Please install npm first.
    exit /b 1
)

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

REM Install frontend dependencies if needed
if not exist "src\netero-app\node_modules\" (
    echo [NETERO] Installing frontend dependencies...
    cd src\netero-app
    call npm install
    cd ..\..
    echo [SUCCESS] Frontend dependencies installed
) else (
    echo [SUCCESS] Frontend dependencies already installed
)

REM Start the orchestration
echo.
echo [NETERO] Starting Ganache in a new window...
start "Ganache" cmd /k "cd src\core && npx ganache --server.port 8545 --chain.chainId 1337"

echo [NETERO] Waiting for Ganache to initialize...
timeout /t 5 /nobreak >nul

echo [NETERO] Deploying smart contracts...
cd src\core
call npx truffle migrate --network development
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Smart contract deployment failed.
    exit /b 1
)
cd ..\..
echo [SUCCESS] Smart contracts deployed

echo [NETERO] Starting Vue.js frontend in a new window...
start "Vue.js Frontend" cmd /k "cd src\netero-app && npm run serve"

echo.
echo ==========================================
echo [SUCCESS] Netero is now running!
echo ==========================================
echo.
echo Frontend: http://localhost:8080
echo Ganache:  http://localhost:8545
echo.
echo Close the terminal windows to stop the services.
echo.
pause
