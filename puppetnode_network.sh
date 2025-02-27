#!/usr/bin/env bash

# Check the current IP assignment and address range of the network interface eth0
# Create a new interface eth1 with a new IP address within the same network range as eth0
# Get the current IP address and subnet mask of eth0
current_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
subnet_mask=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | cut -d'/' -f2)

# Calculate a new IP address within the same subnet
IFS='.' read -r i1 i2 i3 i4 <<< "$current_ip"
new_ip="$i1.$i2.$i3.$((i4 + 1))"

# Create a new interface eth1 with the new IP address
sudo ip link add eth0:1 type dummy
sudo ip addr add "$new_ip/$subnet_mask" dev eth0:1
sudo ip link set eth0:1 up

# Create a startup script to automatically configure eth0:1 on boot
sudo tee /etc/wsl-static-ip.sh <<'EOF'
#!/bin/bash

# Define the interface name and static IP
current_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
subnet_mask=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | cut -d'/' -f2)

IFS='.' read -r i1 i2 i3 i4 <<< "$current_ip"
new_ip="$i1.$i2.$i3.$((i4 + 1))"

# Create a new interface eth1 with the new IP address
sudo ip link add eth0:1 type dummy
sudo ip addr add "$new_ip/$subnet_mask" dev eth0:1
sudo ip link set eth0:1 up
EOF

# Make the script executable
sudo chmod +x /etc/wsl-static-ip.sh

# Add the script to the system profile to run on startup
echo "sudo /etc/wsl-static-ip.sh" | sudo tee -a /etc/profile
