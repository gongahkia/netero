# ----- required imports -----

import subprocess
import threading
import time
import os
import socket

# ----- helper functions -----

def run_ganache():
    print("Starting Ganache on http://127.0.0.1:8545 ...")
    # Keep Ganache running in this thread until killed
    subprocess.run(["npx", "ganache", "--host=127.0.0.1", "--port=8545"], check=True)

def wait_for_port(host: str, port: int, timeout: float = 60.0):
    start = time.time()
    while time.time() - start < timeout:
        try:
            with socket.create_connection((host, port), timeout=1.0):
                return True
        except OSError:
            time.sleep(0.5)
    return False

def run_truffle_migrate():
    print("Waiting for Ganache to be ready...")
    if not wait_for_port("127.0.0.1", 8545, timeout=60.0):
        raise RuntimeError("Ganache did not start listening on 127.0.0.1:8545 in time")
    print("Ganache is up. Running Truffle migrate...")
    subprocess.run(["npx", "truffle", "migrate", "--network", "development", "--reset"], check=True)

# ----- execution code -----

os.chdir('core')
ganache_thread = threading.Thread(target=run_ganache, daemon=True)
migrate_thread = threading.Thread(target=run_truffle_migrate)
ganache_thread.start()
migrate_thread.start()
try:
    migrate_thread.join()
    print("Migration complete. Ganache is running. Press Ctrl+C to stop.")
    # Keep the main thread alive while Ganache runs
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("Shutting down...")
    # Ganache is in a separate process spawned by npx; exiting is enough.
    pass
