#!/usr/bin/env bash

# Create a startup script to automatically configure eth1 on boot
sudo tee /etc/wsl-static-ip.sh <<'EOF'
#!/bin/bash

# Define the interface name and static IP
IFACE="eth0:1"
CURRENT_IP=$(hostname -I | awk '{print $1}')
IFS='.' read -r i1 i2 i3 i4 <<< "$CURRENT_IP"
NEW_IP="$i1.$i2.$i3.$((i4 + 1))"
SUBNET_MASK="24"

# Create a dummy interface and assign the new IP
/sbin/ip link add $IFACE type dummy 2>/dev/null || true
/sbin/ip addr flush dev $IFACE 2>/dev/null
/sbin/ip addr add $NEW_IP/$SUBNET_MASK dev $IFACE
/sbin/ip link set $IFACE up
EOF

# Make the script executable
sudo chmod +x /etc/wsl-static-ip.sh

# Add the script to the system profile to run on startup
echo "sudo /etc/wsl-static-ip.sh" | sudo tee -a /etc/profile
