# ----- required imports -----

import subprocess
import threading
import time
import os

# ----- helper functions -----

def run_ganache():
    print("Starting Ganache...")
    subprocess.run(["npx", "ganache"], check=True)

def run_truffle_migrate():
    print("Running Truffle migrate...")
    subprocess.run(["npx", "truffle", "migrate", "--network", "development"], check=True)

# ----- execution code -----

os.chdir('core')
ganache_thread = threading.Thread(target=run_ganache)
migrate_thread = threading.Thread(target=run_truffle_migrate)
ganache_thread.start()
time.sleep(5)
migrate_thread.start()
ganache_thread.join()
migrate_thread.join()
print("Both tasks completed.")
