#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
ZIP_FILE="$INSTALL_DIR/cursor-app.zip"
APPIMAGE_NAME="cursor-0.42.5x86_64.AppImage"
ICON_NAME="cursor-icon.png"  # Ensure you have the icon file in the same directory
DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

# Download URLs
APPIMAGE_URL="https://download.cursor.sh/linux/appImage/x64/0.42.5/cursor-0.42.5-x86_64.AppImage"
ICON_URL="https://raw.githubusercontent.com/getcursor/cursor/main/apps/desktop/build/icon.png"

# Function to check and install dependencies
install_dependency() {
    if ! dpkg -l | grep -q "$1"; then
        echo "Installing missing dependency: $1"
        sudo apt-get update
        sudo apt-get install -y "$1"
    else
        echo "Dependency $1 is already installed."
    fi
}

# Check and install desktop-file-utils
install_dependency "desktop-file-utils"

# Create necessary directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$DESKTOP_ENTRY_DIR"
mkdir -p "$ICON_DIR"

# First, unzip if the AppImage doesn't exist
if [ ! -f "$INSTALL_DIR/$APPIMAGE_NAME" ] && [ -f "$ZIP_FILE" ]; then
    echo "Extracting AppImage from zip..."
    unzip -o "$ZIP_FILE" -d "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/$APPIMAGE_NAME"
fi

# Replace the icon check and copy block with download logic
if [ ! -f "$ICON_DIR/$ICON_NAME" ]; then
    echo "Downloading $ICON_NAME..."
    curl -L "$ICON_URL" -o "$ICON_DIR/$ICON_NAME"
else
    echo "$ICON_NAME already exists in $ICON_DIR"
fi

# Create the desktop entry
DESKTOP_ENTRY="[Desktop Entry]
Name=Cursor
Exec=\"$INSTALL_DIR/$APPIMAGE_NAME\" --no-sandbox
Icon=$ICON_DIR/$ICON_NAME
Terminal=false
Type=Application
Categories=Development;IDE;
Comment=Cursor is an AI-first coding environment.
StartupWMClass=Cursor"

echo "$DESKTOP_ENTRY" > "$DESKTOP_ENTRY_DIR/cursor.desktop"
chmod +x "$DESKTOP_ENTRY_DIR/cursor.desktop"

# Update desktop database
update-desktop-database "$HOME/.local/share/applications"
gtk-update-icon-cache -f -t "$HOME/.local/share/icons"

# Launch the application (modified)
nohup "$INSTALL_DIR/$APPIMAGE_NAME" --no-sandbox > /dev/null 2>&1 &
