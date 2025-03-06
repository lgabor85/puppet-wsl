#!/usr/bin/env bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Ask for the user name and hostname
echo "Enter the new user name: "
read USER_NAME

echo "Enter the new host name: "
read HOST_NAME

# Create the new user with home directory, sudo privileges, and Bash shell
useradd -m -G sudo -s /bin/bash "$USER_NAME"
if [ $? -ne 0 ]; then
  echo "Failed to create user $USER_NAME" >&2
  exit 1
fi

# Set the password for the new user
passwd "$USER_NAME"
if [ $? -ne 0 ]; then
  echo "Failed to set password for $USER_NAME" >&2
  exit 1
fi

# Add the new user to the sudoers file
echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/"$USER_NAME"
if [ $? -ne 0 ]; then
  echo "Failed to add $USER_NAME to sudoers" >&2
  exit 1
fi

# Add the following to wsl.conf
WSL_CONF="/etc/wsl.conf"
cat <<EOL > "$WSL_CONF"
[boot]
systemd=true

[user]
default=$USER_NAME

[network]
hostname=$HOST_NAME
generateHosts = false
EOL


# Call the puppetnode_network.sh script
./puppetnode_network.sh

# Add the new hostname to /etc/hosts with IP of eth0 in the format: IP HOSTNAME.home HOSTNAME
ETH1_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

cat <<EOL > /etc/hosts
# [network]
# generateHosts = false
127.0.0.1       localhost
127.0.1.1       WS-8VT8PG3.     WS-8VT8PG3
$ETH1_IP  $HOST_NAME.home  $HOST_NAME

10.0.12.181     host.docker.internal
10.0.12.181     gateway.docker.internal
127.0.0.1       kubernetes.docker.internal

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOL

if [ $? -ne 0 ]; then
  echo "Failed to add $HOST_NAME to /etc/hosts" >&2
  exit 1
fi

# Install the OpenSSH server
apt update && apt install -y openssh-server
if [ $? -ne 0 ]; then
  echo "Failed to install OpenSSH server" >&2
  exit 1
fi

# Enable and start the OpenSSH server
systemctl enable ssh && systemctl start ssh
if [ $? -ne 0 ]; then
  echo "Failed to enable/start OpenSSH server" >&2
  exit 1
fi

# Check the status of the OpenSSH server
systemctl status ssh

# Use sed to edit the sshd_config file and uncomment the following lines
SSHD_CONFIG="/etc/ssh/sshd_config"
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' "$SSHD_CONFIG"
sed -i 's/#ListenAddress/ListenAddress/g' "$SSHD_CONFIG"

# Restart the OpenSSH server
systemctl restart ssh
if [ $? -ne 0 ]; then
  echo "Failed to restart OpenSSH server" >&2
  exit 1
fi

# Generate a new SSH key pair
ssh-keygen -t rsa
