#!/bin/bash

echo "Docker Diagnostic and Fix Script"
echo "================================"

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Get the actual username (not root)
ACTUAL_USER=$(logname)

echo "1. Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
else
    echo "Docker is installed."
fi

echo "2. Checking Docker service status..."
if systemctl is-active --quiet docker; then
    echo "Docker service is running."
else
    echo "Docker service is not running. Attempting to start..."
    systemctl start docker
    if systemctl is-active --quiet docker; then
        echo "Docker service started successfully."
    else
        echo "Failed to start Docker service. Please check Docker installation."
        exit 1
    fi
fi

echo "3. Checking user groups..."
if groups $ACTUAL_USER | grep &>/dev/null '\bdocker\b'; then
    echo "User $ACTUAL_USER is in the docker group."
else
    echo "User $ACTUAL_USER is not in the docker group. Adding..."
    usermod -aG docker $ACTUAL_USER
    echo "User added to docker group. A logout/login is required for this to take effect."
fi

echo "4. Checking Docker socket permissions..."
SOCKET_PERMS=$(stat -c '%A' /var/run/docker.sock)
SOCKET_OWNER=$(stat -c '%U' /var/run/docker.sock)
SOCKET_GROUP=$(stat -c '%G' /var/run/docker.sock)
echo "Current permissions: $SOCKET_PERMS, Owner: $SOCKET_OWNER, Group: $SOCKET_GROUP"

if [ "$SOCKET_OWNER" != "root" ] || [ "$SOCKET_GROUP" != "docker" ]; then
    echo "Fixing Docker socket ownership..."
    chown root:docker /var/run/docker.sock
fi

if [ "$SOCKET_PERMS" != "srw-rw----" ]; then
    echo "Fixing Docker socket permissions..."
    chmod 660 /var/run/docker.sock
fi

echo "5. Restarting Docker service..."
systemctl restart docker

echo "Diagnostic complete. Please log out and log back in, then try 'docker image ls' again."
echo "If you still encounter issues, please run 'docker image ls' with sudo and share the output."
