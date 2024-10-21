#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Arrays to keep track of installation statuses
installed_tools=()
failed_tools=()

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package lists
echo "Updating package lists..."
sudo apt update -y

### Terminal and Productivity Tools ###

# Install fzf: Command-line fuzzy finder
if command_exists fzf; then
    echo "fzf is already installed."
else
    echo "Installing fzf..."
    if sudo apt install -y fzf; then
        installed_tools+=("fzf")
    else
        echo "Failed to install fzf."
        failed_tools+=("fzf")
    fi
fi

# Install bat: Clone of cat with syntax highlighting
if command_exists batcat; then
    echo "bat is already installed."
else
    echo "Installing bat..."
    if sudo apt install -y bat; then
        # Create an alias for batcat to bat
        if ! grep -Fxq "alias bat='batcat'" ~/.bashrc; then
            echo "alias bat='batcat'" >> ~/.bashrc
        fi
        installed_tools+=("bat")
    else
        echo "Failed to install bat."
        failed_tools+=("bat")
    fi
fi

# Install ripgrep (rg): Fast recursive search tool
if command_exists rg; then
    echo "ripgrep is already installed."
else
    echo "Installing ripgrep..."
    if sudo apt install -y ripgrep; then
        installed_tools+=("ripgrep")
    else
        echo "Failed to install ripgrep."
        failed_tools+=("ripgrep")
    fi
fi

# Install exa (replaced by eza): Modern replacement for ls
if command_exists exa || command_exists eza; then
    echo "exa/eza is already installed."
else
    echo "Installing eza (replacement for exa)..."
    if sudo apt install -y eza; then
        # Create an alias for eza to exa for compatibility
        if ! grep -Fxq "alias exa='eza'" ~/.bashrc; then
            echo "alias exa='eza'" >> ~/.bashrc
        fi
        installed_tools+=("eza (replacement for exa)")
    else
        echo "Failed to install eza."
        failed_tools+=("eza (exa)")
    fi
fi

# Install tldr: Simplified man pages
if command_exists tldr; then
    echo "tldr is already installed."
else
    echo "Installing tldr..."
    if sudo apt install -y tldr; then
        installed_tools+=("tldr")
    else
        echo "Failed to install tldr."
        failed_tools+=("tldr")
    fi
fi

# Install The Silver Searcher (ag): Code-searching tool
if command_exists ag; then
    echo "ag is already installed."
else
    echo "Installing The Silver Searcher..."
    if sudo apt install -y silversearcher-ag; then
        installed_tools+=("The Silver Searcher (ag)")
    else
        echo "Failed to install The Silver Searcher."
        failed_tools+=("The Silver Searcher (ag)")
    fi
fi

# Install autojump: Fast directory navigation
if command_exists autojump; then
    echo "autojump is already installed."
else
    echo "Installing autojump..."
    if sudo apt install -y autojump; then
        # Add autojump to .bashrc
        if ! grep -Fxq ". /usr/share/autojump/autojump.sh" ~/.bashrc; then
            echo ". /usr/share/autojump/autojump.sh" >> ~/.bashrc
        fi
        installed_tools+=("autojump")
    else
        echo "Failed to install autojump."
        failed_tools+=("autojump")
    fi
fi

# Install z: Directory jumper
if command_exists z; then
    echo "z is already installed."
else
    echo "Installing z..."
    if sudo apt install -y zoxide; then
        # Add zoxide initialization to .bashrc
        if ! grep -Fxq "eval \"\$(zoxide init bash)\"" ~/.bashrc; then
            echo "eval \"\$(zoxide init bash)\"" >> ~/.bashrc
        fi
        installed_tools+=("z (zoxide)")
    else
        echo "Failed to install zoxide."
        failed_tools+=("z (zoxide)")
    fi
fi

# Install direnv: Environment variable manager
if command_exists direnv; then
    echo "direnv is already installed."
else
    echo "Installing direnv..."
    if sudo apt install -y direnv; then
        # Add direnv hook to .bashrc
        if ! grep -Fxq 'eval "$(direnv hook bash)"' ~/.bashrc; then
            echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
        fi
        installed_tools+=("direnv")
    else
        echo "Failed to install direnv."
        failed_tools+=("direnv")
    fi
fi


### Container and Kubernetes Tools ###

# Install k9s: Kubernetes CLI management tool
if command_exists k9s; then
    echo "k9s is already installed."
else
    echo "Installing k9s..."
    if curl -Lo k9s.tar.gz https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_x86_64.tar.gz && \
       tar -xzf k9s.tar.gz k9s && sudo mv k9s /usr/local/bin/ && rm k9s.tar.gz; then
        installed_tools+=("k9s")
    else
        echo "Failed to install k9s."
        failed_tools+=("k9s")
    fi
fi

# Install kubectx and kubens: Kubernetes context and namespace switcher
if command_exists kubectx; then
    echo "kubectx is already installed."
else
    echo "Installing kubectx and kubens..."
    if sudo apt install -y kubectx; then
        installed_tools+=("kubectx and kubens")
    else
        echo "Failed to install kubectx and kubens."
        failed_tools+=("kubectx and kubens")
    fi
fi

# Install Kustomize: Kubernetes native configuration management
if command_exists kustomize; then
    echo "Kustomize is already installed."
else
    echo "Installing Kustomize..."
    if sudo apt install -y kustomize; then
        installed_tools+=("Kustomize")
    else
        echo "Failed to install Kustomize."
        failed_tools+=("Kustomize")
    fi
fi

# Continue with the rest of the tools following the same pattern...

### Networking and Security Tools ###

# Install Trivy: Vulnerability scanner
if command_exists trivy; then
    echo "Trivy is already installed."
else
    echo "Installing Trivy..."
    if sudo apt install -y trivy; then
        installed_tools+=("Trivy")
    else
        echo "Failed to install Trivy."
        failed_tools+=("Trivy")
    fi
fi

# Handle other tools similarly...

### Summary ###

echo ""
echo "Installation Summary:"
echo "---------------------"
echo "Successfully installed tools (${#installed_tools[@]}):"
for tool in "${installed_tools[@]}"; do
    echo "- $tool"
done

if [ ${#failed_tools[@]} -gt 0 ]; then
    echo ""
    echo "Failed to install tools (${#failed_tools[@]}):"
    for tool in "${failed_tools[@]}"; do
        echo "- $tool"
    done
fi

# Reminder to source .bashrc
echo ""
echo "Please run 'source ~/.bashrc' or restart your terminal to apply changes."

