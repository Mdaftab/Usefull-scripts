#!/bin/bash



# Exit immediately if a command exits with a non-zero status
set -e

# Update package lists
echo "Updating package lists..."
sudo apt update -y

# Install dependencies
echo "Installing dependencies..."
sudo apt install -y curl wget apt-transport-https

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install autojump: Fast directory navigation
if command_exists autojump; then
    echo "autojump is already installed."
else
    echo "Installing autojump..."
    sudo apt install -y autojump
    # Add autojump to .bashrc
    if ! grep -Fxq ". /usr/share/autojump/autojump.sh" ~/.bashrc; then
        echo ". /usr/share/autojump/autojump.sh" >> ~/.bashrc
    fi
    installed_tools+=("autojump")
fi

# Install z: Directory jumper
if command_exists z; then
    echo "z is already installed."
else
    echo "Installing z..."
    sudo apt install -y zoxide
    # Add zoxide initialization to .bashrc
    if ! grep -Fxq "eval \"\$(zoxide init bash)\"" ~/.bashrc; then
        echo "eval \"\$(zoxide init bash)\"" >> ~/.bashrc
    fi
    installed_tools+=("z (zoxide)")
fi

# Install direnv: Environment variable manager
if command_exists direnv; then
    echo "direnv is already installed."
else
    echo "Installing direnv..."
    sudo apt install -y direnv
    # Add direnv hook to .bashrc
    if ! grep -Fxq 'eval "$(direnv hook bash)"' ~/.bashrc; then
        echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
    fi
    installed_tools+=("direnv")
fi



### Container and Kubernetes Tools ###

# Install k9s: Kubernetes CLI
if command_exists k9s; then
    echo "k9s is already installed."
else
    echo "Installing k9s..."
    curl -Lo k9s.tar.gz https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_x86_64.tar.gz
    tar -xzf k9s.tar.gz k9s
    sudo mv k9s /usr/local/bin/
    rm k9s.tar.gz
    installed_tools+=("k9s")
fi

# Install Docker
if command_exists docker; then
    echo "Docker is already installed."
else
    echo "Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    installed_tools+=("Docker")
fi

# Install Docker Compose
if command_exists docker-compose; then
    echo "Docker Compose is already installed."
else
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    installed_tools+=("Docker Compose")
fi

### SSL/TLS Protocols and Ciphers ###

print_header "Supported SSL/TLS Protocols"
for protocol in tls1 tls1_1 tls1_2 tls1_3; do
    echo -e "${CYAN}  Checking $protocol...${NC}"
    result=$(openssl s_client -$protocol -connect $domain:443 < /dev/null 2>&1)
    if echo "$result" | grep -q "CONNECTED"; then
        echo -e "${GREEN}  $protocol is supported${NC}"
    else
        echo -e "${RED}  $protocol is not supported${NC}"
        echo -e "${RED}  Error: $result${NC}"
    fi
done

### Summary ###

print_header "Installation Summary"
echo -e "${GREEN}  Installed tools: ${NC}"
for tool in "${installed_tools[@]}"; do
    echo -e "  ${tool}"
done
echo -e "${RED}  Failed tools: ${NC}"
for tool in "${failed_tools[@]}"; do
    echo -e "  ${tool}"
done