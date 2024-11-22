#!/bin/bash

#==============================================================================
# Script Name: ubuntu-tools-installer.sh
# Description: Installs a curated set of useful command-line tools on Ubuntu
# Author: System Administrator
# Date Created: 2024-11-22
# Version: 1.0
# Dependencies: apt, git, python3, pip3
# Usage: sudo bash ubuntu-tools-installer.sh
#==============================================================================

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

#==============================================================================
# Constants
#==============================================================================
readonly LOG_FILE="/tmp/tools-installer-$(date +%Y%m%d-%H%M%S).log"
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color
# Add array of tools for easier management
readonly TOOLS=(
    "cowsay"
    "shellcheck"
    "tree"
    "htop"
)

#==============================================================================
# Functions
#==============================================================================

log() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} - ${message}" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    log "${RED}ERROR: ${message}${NC}"
}

log_success() {
    local message="$1"
    log "${GREEN}SUCCESS: ${message}${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (sudo)"
        exit 1
    fi
}

check_dependencies() {
    local deps=("git")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "Installing dependency: $dep"
            apt-get install -y "$dep"
        fi
    done
}

update_system() {
    log "Updating package lists..."
    apt-get update || {
        log_error "Failed to update package lists"
        exit 1
    }
}

# Replace individual install functions with a single generic one
install_tool() {
    local tool="$1"
    log "Installing ${tool}..."
    if ! command -v "$tool" &> /dev/null; then
        apt-get install -y "$tool" || {
            log_error "Failed to install ${tool}"
            return 1
        }
        log_success "${tool} installed successfully"
    else
        log "${tool} is already installed"
    fi
}

cleanup() {
    log "Cleaning up..."
    apt-get autoremove -y
    apt-get clean
}

print_completion_message() {
    echo -e "\n${GREEN}Installation Complete!${NC}"
    echo "Please run 'source ~/.bashrc' to activate the new tools"
    echo "Log file is available at: $LOG_FILE"
    cowsay "Installation Complete! Happy Computing!"
}

#==============================================================================
# Main Script Execution
#==============================================================================

main() {
    log "Starting tools installation..."
    
    # Prerequisite checks
    check_root
    update_system
    check_dependencies
    
    # Install all tools using a loop
    for tool in "${TOOLS[@]}"; do
        install_tool "$tool"
    done
    
    # Cleanup and finish
    cleanup
    print_completion_message
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Execute main function
main