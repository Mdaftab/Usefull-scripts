#!/bin/bash

# Go Environment Setup Script for Ubuntu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    printf "${!1}%s${NC}\n" "$2"
}

# Check if script is run with sudo
if [[ $EUID -ne 0 ]]; then
   print_color "RED" "This script must be run with sudo privileges. Please run with sudo."
   exit 1
fi

# Update system
print_color "YELLOW" "Updating system..."
apt update && apt upgrade -y

# Install required dependencies
print_color "YELLOW" "Installing required dependencies..."
apt install -y curl wget git

# Set Go version
GO_VERSION="1.20.5"  # You can change this to the version you prefer

# Download and install Go
print_color "YELLOW" "Downloading and installing Go ${GO_VERSION}..."
wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

# Set up Go environment variables
print_color "YELLOW" "Setting up Go environment variables..."
echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
echo "export GOPATH=\$HOME/go" >> /etc/profile
echo "export PATH=\$PATH:\$GOPATH/bin" >> /etc/profile

# Source the profile to apply changes immediately
source /etc/profile

# Create Go workspace directories
print_color "YELLOW" "Creating Go workspace directories..."
mkdir -p $HOME/go/{bin,src,pkg}

# Install commonly used Go packages
print_color "YELLOW" "Installing commonly used Go packages..."
go get -u github.com/fatih/color
go get -u github.com/shirou/gopsutil

# Verify installation
print_color "YELLOW" "Verifying Go installation..."
go version

# Print Go environment information
print_color "YELLOW" "Go environment information:"
go env

print_color "GREEN" "Go environment setup completed successfully!"
print_color "YELLOW" "Please log out and log back in, or run 'source /etc/profile' to apply the changes to your current session."