<template>
  <div class="wallet-connection">
    <div class="connection-status" :class="statusClass">
      <div class="status-header">
        <span class="status-icon">{{ statusIcon }}</span>
        <span class="status-text">{{ statusText }}</span>
      </div>

      <div v-if="account" class="account-info">
        <span class="account-label">// CONNECTED_WALLET:</span>
        <span class="account-address">{{ formatAddress(account) }}</span>
      </div>

      <div v-if="error" class="error-message">
        <span class="error-label">// ERROR:</span>
        <span class="error-text">{{ error }}</span>
      </div>

      <button
        v-if="!isConnected && !isConnecting"
        @click="connectWallet"
        class="btn btn-primary connect-btn"
      >
        [ CONNECT_WALLET ]
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'WalletConnection',
  data() {
    return {
      isConnecting: false,
      isConnected: false,
      account: null,
      error: null
    }
  },
  computed: {
    statusClass() {
      if (this.error) return 'status-error';
      if (this.isConnecting) return 'status-connecting';
      if (this.isConnected) return 'status-connected';
      return 'status-disconnected';
    },
    statusIcon() {
      if (this.error) return '✕';
      if (this.isConnecting) return '⟳';
      if (this.isConnected) return '✓';
      return '○';
    },
    statusText() {
      if (this.error) return 'CONNECTION_FAILED';
      if (this.isConnecting) return 'CONNECTING...';
      if (this.isConnected) return 'CONNECTED';
      return 'NOT_CONNECTED';
    }
  },
  async mounted() {
    await this.checkConnection();

    // Listen for account changes
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', this.handleAccountsChanged);
      window.ethereum.on('chainChanged', () => window.location.reload());
    }
  },
  beforeUnmount() {
    if (window.ethereum) {
      window.ethereum.removeListener('accountsChanged', this.handleAccountsChanged);
    }
  },
  methods: {
    async checkConnection() {
      if (!window.ethereum) {
        this.error = 'MetaMask not detected. Please install MetaMask.';
        return;
      }

      try {
        const accounts = await window.ethereum.request({ method: 'eth_accounts' });
        if (accounts.length > 0) {
          this.account = accounts[0];
          this.isConnected = true;
          this.$emit('connected', this.account);
        }
      } catch (err) {
        console.error('Error checking connection:', err);
      }
    },
    async connectWallet() {
      if (!window.ethereum) {
        this.error = 'MetaMask not detected. Please install MetaMask from metamask.io';
        return;
      }

      this.isConnecting = true;
      this.error = null;

      try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });

        if (accounts.length > 0) {
          this.account = accounts[0];
          this.isConnected = true;
          this.$emit('connected', this.account);
        }
      } catch (err) {
        console.error('Connection error:', err);

        if (err.code === 4001) {
          this.error = 'Connection rejected by user';
        } else {
          this.error = 'Failed to connect to MetaMask';
        }

        this.$emit('error', err);
      } finally {
        this.isConnecting = false;
      }
    },
    handleAccountsChanged(accounts) {
      if (accounts.length === 0) {
        this.isConnected = false;
        this.account = null;
        this.$emit('disconnected');
      } else if (accounts[0] !== this.account) {
        this.account = accounts[0];
        this.$emit('connected', this.account);
      }
    },
    formatAddress(address) {
      if (!address) return '';
      return `${address.slice(0, 6)}...${address.slice(-4)}`;
    }
  }
}
</script>

<style scoped>
.wallet-connection {
  margin-bottom: 20px;
}

.connection-status {
  padding: 16px 20px;
  border: 2px solid var(--border);
  background: var(--bg-surface);
  transition: border-color 0.3s ease;
}

.status-connected {
  border-color: var(--text-primary);
}

.status-connecting {
  border-color: var(--text-secondary);
}

.status-error {
  border-color: var(--text-primary);
}

.status-disconnected {
  border-color: var(--border);
}

.status-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.status-icon {
  font-size: 18px;
  font-weight: 700;
}

.status-connected .status-icon {
  color: var(--text-primary);
}

.status-connecting .status-icon {
  color: var(--text-secondary);
  animation: spin 1s linear infinite;
}

.status-error .status-icon {
  color: var(--text-primary);
}

.status-disconnected .status-icon {
  color: var(--text-muted);
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.status-text {
  font-size: 13px;
  font-weight: 600;
  letter-spacing: 1px;
  color: var(--text-primary);
}

.account-info {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 12px;
  background: var(--bg-muted);
  border: 1px solid var(--border);
  margin-bottom: 12px;
}

.account-label {
  font-size: 11px;
  color: var(--text-muted);
  letter-spacing: 1px;
}

.account-address {
  font-size: 14px;
  color: var(--text-primary);
  font-weight: 600;
  font-family: monospace;
}

.error-message {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 12px;
  background: var(--bg-muted);
  border: 1px solid var(--text-primary);
  margin-bottom: 12px;
}

.error-label {
  font-size: 11px;
  color: var(--text-muted);
  letter-spacing: 1px;
}

.error-text {
  font-size: 13px;
  color: var(--text-primary);
  line-height: 1.5;
}

.connect-btn {
  width: 100%;
}
</style>
