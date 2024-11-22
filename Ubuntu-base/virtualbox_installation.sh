#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update the package list
echo "Updating package list..."
sudo apt-get update -y

# Check for required dependencies and install if missing
echo "Checking for required dependencies..."
required_packages=("curl" "dkms" "linux-headers-$(uname -r)")

for pkg in "${required_packages[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Installing missing dependency: $pkg"
        sudo apt-get install -y "$pkg"
    else
        echo "$pkg is already installed"
    fi
done

# Check if VirtualBox is already installed
if command_exists vboxmanage; then
    echo "VirtualBox is already installed."
else
    # Download and install VirtualBox
    echo "Downloading and installing VirtualBox..."
    sudo apt-get install -y virtualbox
fi

# Verify VirtualBox installation
echo "Verifying VirtualBox installation..."
if command_exists vboxmanage; then
    echo "VirtualBox successfully installed. Version info:"
    vboxmanage --version
else
    echo "Error: VirtualBox installation failed."
    exit 1
fi

# Test VirtualBox functionality by listing VMs (should return empty if no VMs are present)
echo "Running VirtualBox basic functionality test..."
vms=$(vboxmanage list vms)
if [[ $? -eq 0 ]]; then
    echo "VirtualBox is functioning correctly."
    echo "Available VMs (if any):"
    echo "$vms"
else
    echo "VirtualBox functionality test failed. Please check the installation."
    exit 1
fi

echo "VirtualBox installation and tests completed successfully!"

