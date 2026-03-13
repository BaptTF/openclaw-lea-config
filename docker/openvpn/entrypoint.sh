#!/bin/sh
set -e

CONFIG=$(find /vpn -name '*.ovpn' -o -name '*.conf' | head -1)

if [ -z "$CONFIG" ]; then
    echo "ERROR: No .ovpn or .conf file found in /vpn/"
    exit 1
fi

echo "Starting OpenVPN with $CONFIG ..."

# Copy config to writable location and fix auth-user-pass path
cp "$CONFIG" /tmp/vpn.conf
if [ -f /vpn/auth.txt ]; then
    sed -i 's|auth-user-pass.*|auth-user-pass /vpn/auth.txt|' /tmp/vpn.conf
    # Ensure auth-user-pass directive exists
    grep -q 'auth-user-pass' /tmp/vpn.conf || echo "auth-user-pass /vpn/auth.txt" >> /tmp/vpn.conf
fi

# Start OpenVPN in background
openvpn --config /tmp/vpn.conf --daemon --log /tmp/openvpn.log

# Wait for tun0 to come up
echo "Waiting for tun0 ..."
for i in $(seq 1 30); do
    if ip addr show tun0 >/dev/null 2>&1; then
        TUN_IP=$(ip -4 addr show tun0 | awk '/inet /{print $2}' | cut -d/ -f1)
        echo "tun0 up with IP $TUN_IP"
        break
    fi
    sleep 1
done

if ! ip addr show tun0 >/dev/null 2>&1; then
    echo "ERROR: tun0 did not come up after 30s"
    cat /tmp/openvpn.log
    exit 1
fi

# Generate tinyproxy config — bind outgoing traffic to VPN tunnel IP
cat > /tmp/tinyproxy.conf <<EOF
Port 8888
Listen 0.0.0.0
Bind ${TUN_IP}
Timeout 600
MaxClients 50
Allow 0.0.0.0/0
EOF

echo "Starting HTTP proxy on 0.0.0.0:8888 (outbound via $TUN_IP) ..."
exec tinyproxy -d -c /tmp/tinyproxy.conf
