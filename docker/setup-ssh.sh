#!/bin/bash
set -e

SSH_PORT="${OPENCLAW_SSH_PORT:-22}"
SSH_USER="node"
SSH_HOME="/home/node"

# Create .ssh directory
mkdir -p "$SSH_HOME/.ssh"
chmod 700 "$SSH_HOME/.ssh"

# Add authorized keys from environment or mounted file
if [ -n "${OPENCLAW_SSH_AUTHORIZED_KEYS:-}" ]; then
  echo "$OPENCLAW_SSH_AUTHORIZED_KEYS" > "$SSH_HOME/.ssh/authorized_keys"
elif [ -f "/run/secrets/ssh_authorized_keys" ]; then
  cp /run/secrets/ssh_authorized_keys "$SSH_HOME/.ssh/authorized_keys"
elif [ -f "/ssh/authorized_keys" ]; then
  cp /ssh/authorized_keys "$SSH_HOME/.ssh/authorized_keys"
fi

# Set permissions
chmod 600 "$SSH_HOME/.ssh/authorized_keys" 2>/dev/null || true
chown -R "$SSH_USER:$SSH_USER" "$SSH_HOME/.ssh"

# Configure sshd for security
cat > /etc/ssh/sshd_config.d/openclaw.conf <<EOF
Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers $SSH_USER
X11Forwarding no
EOF

# Persist host keys in /home so they survive container rebuilds
# (prevents SSH "REMOTE HOST IDENTIFICATION HAS CHANGED" warnings)
PERSISTENT_HOST_KEYS="/home/node/.ssh/host_keys"
mkdir -p "$PERSISTENT_HOST_KEYS"

# If we have persisted keys from a previous run, restore them
if ls "$PERSISTENT_HOST_KEYS"/ssh_host_* &>/dev/null; then
  cp "$PERSISTENT_HOST_KEYS"/ssh_host_* /etc/ssh/
  echo "==> Restored SSH host keys from persistent storage"
fi

# Generate host keys if they don't exist (first boot only)
ssh-keygen -A

# Persist newly generated keys back to /home
cp /etc/ssh/ssh_host_* "$PERSISTENT_HOST_KEYS/"

echo "==> SSH server configured on port $SSH_PORT for user $SSH_USER"
