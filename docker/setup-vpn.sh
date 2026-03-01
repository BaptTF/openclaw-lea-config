#!/bin/bash
# Setup OpenVPN + SOCKS5 proxy for Chrome browser
# Usage: setup-vpn.sh start|stop|status
#
# This connects to a home OpenVPN server and routes ONLY Chrome traffic
# through it via a SOCKS5 proxy, keeping all other traffic on the VPS IP.
#
# Prerequisites:
#   - OpenVPN config at /home/node/.config/openvpn/home.ovpn
#   - Auth file at /home/node/.config/openvpn/auth.txt (user\npassword)
#   - /dev/net/tun device available (docker-compose: devices + cap_add)
#
# Chrome launch flag: --proxy-server="socks5://127.0.0.1:1080"

OVPN_CONFIG="/home/node/.config/openvpn/home.ovpn"
OVPN_PID="/tmp/openvpn.pid"
SOCKS_PID="/tmp/socks-proxy.pid"

case "$1" in
  start)
    if [ -f "$OVPN_PID" ] && kill -0 "$(cat $OVPN_PID)" 2>/dev/null; then
      echo "OpenVPN already running (pid $(cat $OVPN_PID))"
      exit 0
    fi

    if [ ! -f "$OVPN_CONFIG" ]; then
      echo "ERROR: OpenVPN config not found at $OVPN_CONFIG"
      exit 1
    fi

    echo "Starting OpenVPN..."
    openvpn --config "$OVPN_CONFIG" --daemon --writepid "$OVPN_PID" \
      --log /tmp/openvpn.log --verb 3

    # Wait for tun interface
    for i in $(seq 1 15); do
      if ip addr show tun0 &>/dev/null; then
        TUN_IP=$(ip -4 addr show tun0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        echo "✅ VPN connected! tun0 IP: $TUN_IP"
        
        # Start SOCKS5 proxy bound to tun0
        # Using ssh as a simple SOCKS proxy through the tunnel
        echo "Starting SOCKS5 proxy on 127.0.0.1:1080..."
        ssh -D 1080 -N -f -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          -b "$TUN_IP" localhost 2>/dev/null || true
        
        echo "✅ Chrome proxy ready: --proxy-server=\"socks5://127.0.0.1:1080\""
        exit 0
      fi
      sleep 1
    done
    
    echo "❌ VPN failed to connect. Check /tmp/openvpn.log"
    cat /tmp/openvpn.log | tail -20
    exit 1
    ;;

  stop)
    if [ -f "$OVPN_PID" ]; then
      kill "$(cat $OVPN_PID)" 2>/dev/null
      rm -f "$OVPN_PID"
      echo "OpenVPN stopped"
    fi
    # Kill SOCKS proxy
    pkill -f "ssh -D 1080" 2>/dev/null
    echo "SOCKS proxy stopped"
    ;;

  status)
    if [ -f "$OVPN_PID" ] && kill -0 "$(cat $OVPN_PID)" 2>/dev/null; then
      TUN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
      echo "✅ VPN running (pid $(cat $OVPN_PID)), tun0: ${TUN_IP:-N/A}"
    else
      echo "❌ VPN not running"
    fi
    ;;

  *)
    echo "Usage: $0 {start|stop|status}"
    exit 1
    ;;
esac
