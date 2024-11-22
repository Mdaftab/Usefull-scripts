#!/bin/bash

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display step separators
display_step() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Update system
display_step "Updating system"
if apt update && apt upgrade -y; then
    echo -e "${GREEN}System updated successfully.${NC}"
else
    echo -e "${YELLOW}System update skipped or failed. Continuing with installation.${NC}"
fi

# Install dependencies
display_step "Installing dependencies"
if apt install -y curl wget apt-transport-https; then
    echo -e "${GREEN}Dependencies installed successfully.${NC}"
else
    echo -e "${YELLOW}Some dependencies may not have installed correctly. Continuing with installation.${NC}"
fi

# Install Docker if not already installed
display_step "Checking Docker installation"
if command_exists docker; then
    echo -e "${GREEN}Docker is already installed.${NC}"
else
    echo "Installing Docker..."
    if apt install -y docker.io && systemctl start docker && systemctl enable docker; then
        echo -e "${GREEN}Docker installed and started successfully.${NC}"
    else
        echo -e "${YELLOW}Docker installation failed. Please install Docker manually.${NC}"
        exit 1
    fi
fi

# Add user to docker group
display_step "Adding user to docker group"
if groups $SUDO_USER | grep -q '\bdocker\b'; then
    echo -e "${GREEN}User is already in the docker group.${NC}"
else
    if usermod -aG docker $SUDO_USER; then
        echo -e "${GREEN}User added to docker group successfully.${NC}"
    else
        echo -e "${YELLOW}Failed to add user to docker group. Please do this manually.${NC}"
    fi
fi

# Install Minikube if not already installed
display_step "Checking Minikube installation"
if command_exists minikube; then
    echo -e "${GREEN}Minikube is already installed.${NC}"
else
    echo "Installing Minikube..."
    if curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
       install minikube-linux-amd64 /usr/local/bin/minikube && \
       rm minikube-linux-amd64; then
        echo -e "${GREEN}Minikube installed successfully.${NC}"
    else
        echo -e "${YELLOW}Minikube installation failed. Please install Minikube manually.${NC}"
        exit 1
    fi
fi

# Install kubectl if not already installed
display_step "Checking kubectl installation"
if command_exists kubectl; then
    echo -e "${GREEN}kubectl is already installed.${NC}"
else
    echo "Installing kubectl..."
    if curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
       install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
       rm kubectl; then
        echo -e "${GREEN}kubectl installed successfully.${NC}"
    else
        echo -e "${YELLOW}kubectl installation failed. Please install kubectl manually.${NC}"
        exit 1
    fi
fi

# Start Minikube
display_step "Starting Minikube"
if sudo -u $SUDO_USER minikube status &>/dev/null; then
    echo -e "${GREEN}Minikube is already running.${NC}"
else
    if sudo -u $SUDO_USER minikube start --driver=docker; then
        echo -e "${GREEN}Minikube started successfully.${NC}"
    else
        echo -e "${YELLOW}Failed to start Minikube. Please check your Docker installation and try again.${NC}"
        exit 1
    fi
fi

# Verify installation
display_step "Verifying installation"
if sudo -u $SUDO_USER kubectl get nodes; then
    echo -e "${GREEN}Kubernetes node verified successfully.${NC}"
else
    echo -e "${YELLOW}Failed to verify Kubernetes node. Please check your installation.${NC}"
    exit 1
fi

# Deploy a small application (Hello World web app)
display_step "Deploying a small Hello World application"
cat <<EOF | sudo -u $SUDO_USER kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world
spec:
  type: NodePort
  selector:
    app: hello-world
  ports:
  - port: 8080
    targetPort: 8080
EOF

echo "Waiting for deployment to be ready..."
sudo -u $SUDO_USER kubectl wait --for=condition=available --timeout=600s deployment/hello-world

# Get the URL of the service
SERVICE_URL=$(sudo -u $SUDO_USER minikube service hello-world --url)

echo -e "${GREEN}Hello World application deployed successfully!${NC}"
echo -e "You can access the application at: ${BLUE}$SERVICE_URL${NC}"

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}  Minikube installation and deployment complete!${NC}"
echo -e "${GREEN}  A small Hello World application has been deployed.${NC}"
echo -e "${GREEN}  You can access it at: $SERVICE_URL${NC}"
echo -e "${GREEN}==========================================${NC}"