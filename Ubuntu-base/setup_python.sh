#!/bin/bash

# Set error handling
set -e

# Global variables
LOGFILE="/tmp/python_setup_$(date +%Y%m%d_%H%M%S).log"
RETRY_LIMIT=3
SUDO_AVAILABLE=false

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function for logging
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "${LOGFILE}"
}

# Function for error logging
error_log() {
    log "${RED}ERROR: $1${NC}"
}

# Function for warning logging
warn_log() {
    log "${YELLOW}WARNING: $1${NC}"
}

# Function for success logging
success_log() {
    log "${GREEN}SUCCESS: $1${NC}"
}

# Function to check internet connectivity
check_internet() {
    local retry=0
    while ! ping -c 1 8.8.8.8 > /dev/null 2>&1; do
        retry=$((retry + 1))
        if [ $retry -ge $RETRY_LIMIT ]; then
            error_log "No internet connection available after $RETRY_LIMIT attempts"
            return 1
        fi
        warn_log "No internet connection. Retrying in 5 seconds... (Attempt $retry/$RETRY_LIMIT)"
        sleep 5
    done
    success_log "Internet connection verified"
}

# Function to check sudo access
check_sudo() {
    if ! command -v sudo > /dev/null 2>&1; then
        error_log "Sudo is not installed. Please install sudo first."
        return 1
    fi

    if ! sudo -n true 2>/dev/null; then
        warn_log "Sudo requires password. You may be prompted for your password."
        if ! sudo -v; then
            error_log "Failed to get sudo access"
            return 1
        fi
    fi
    
    SUDO_AVAILABLE=true
    success_log "Sudo access verified"
}

# Function to check disk space
check_disk_space() {
    local required_space=5120 # 5GB in MB
    local available_space
    available_space=$(df -m /usr | awk 'NR==2 {print $4}')
    
    if [ "${available_space}" -lt "${required_space}" ]; then
        error_log "Insufficient disk space. Required: ${required_space}MB, Available: ${available_space}MB"
        return 1
    fi
    success_log "Sufficient disk space available"
}

# Function to handle package installation with retry
apt_install() {
    local package="$1"
    local retry=0
    
    while ! sudo apt-get install -y "$package" >> "${LOGFILE}" 2>&1; do
        retry=$((retry + 1))
        if [ $retry -ge $RETRY_LIMIT ]; then
            error_log "Failed to install $package after $RETRY_LIMIT attempts"
            return 1
        fi
        warn_log "Failed to install $package. Retrying... (Attempt $retry/$RETRY_LIMIT)"
        sudo apt-get update -qq
        sleep 2
    done
    success_log "Successfully installed $package"
}

# Function to install dependencies
install_dependencies() {
    log "Updating package lists..."
    if ! sudo apt-get update >> "${LOGFILE}" 2>&1; then
        error_log "Failed to update package lists"
        return 1
    fi

    local packages=(
        wget
        software-properties-common
        build-essential
        libssl-dev
        libffi-dev
        python3-dev
        python3-pip
        python3-venv
    )

    for package in "${packages[@]}"; do
        if ! apt_install "$package"; then
            return 1
        fi
    done
}

# Function to install Python 
install_python() {
    log "Adding deadsnakes PPA..."
    if ! sudo add-apt-repository -y ppa:deadsnakes/ppa >> "${LOGFILE}" 2>&1; then
        error_log "Failed to add deadsnakes PPA"
        return 1
    fi
    
    if ! sudo apt-get update >> "${LOGFILE}" 2>&1; then
        error_log "Failed to update package lists after adding PPA"
        return 1
    fi
    
    local latest_python
    latest_python=$(apt-cache search "^python3\.[0-9]+$" | sort -V | tail -n 1 | cut -d' ' -f1)
    
    log "Installing $latest_python..."
    if ! apt_install "$latest_python"; then
        return 1
    fi
    
    # Install pip for the latest Python version
    local python_version
    python_version=$(echo "$latest_python" | cut -d'n' -f2)
    apt_install "${latest_python}-pip"
    apt_install "${latest_python}-venv"
}

# Function to create virtual environment
create_virtualenv() {
    local project_dir="$1"
    local venv_name="$2"

    log "Creating project directory at $project_dir..."
    mkdir -p "$project_dir"
    cd "$project_dir" || return 1

    log "Creating virtual environment..."
    python3 -m venv "$venv_name"
    
    log "Activating virtual environment..."
    # shellcheck disable=SC1090
    source "$venv_name/bin/activate"

    log "Upgrading pip..."
    pip install --upgrade pip >> "${LOGFILE}" 2>&1

    local packages=(
        pytest
        black
        flake8
        mypy
        ipython
        notebook
        requests
        pandas
        numpy
    )

    for package in "${packages[@]}"; do
        log "Installing $package..."
        if ! pip install "$package" >> "${LOGFILE}" 2>&1; then
            error_log "Failed to install $package"
            return 1
        fi
    done
}

# Function to run tests
run_tests() {
    local project_dir="$1"
    local venv_name="$2"

    log "Running Python version test..."
    if ! python3 --version; then
        error_log "Python version test failed"
        return 1
    fi

    log "Running pip test..."
    if ! pip --version; then
        error_log "Pip version test failed"
        return 1
    fi

    log "Testing virtual environment..."
    if ! which python | grep -q "$venv_name"; then
        error_log "Virtual environment test failed"
        return 1
    fi

    success_log "All tests passed!"
}

# Main execution
main() {
    local project_dir="$HOME/python_projects"
    local venv_name="venv"

    log "Starting Python environment setup..."
    
    # Pre-installation checks
    check_sudo || return 1
    check_internet || return 1
    check_disk_space || return 1
    
    # Main installation steps
    install_dependencies || return 1
    install_python || return 1
    create_virtualenv "$project_dir" "$venv_name" || return 1
    run_tests "$project_dir" "$venv_name" || return 1

    success_log "Setup completed successfully!"
    log "To activate the virtual environment, run: source $project_dir/$venv_name/bin/activate"
    log "Setup log available at: $LOGFILE"
}

# Execute main function
main || {
    error_log "Script failed. Please check $LOGFILE for details"
    exit 1
}

success_log "Script completed successfully!"