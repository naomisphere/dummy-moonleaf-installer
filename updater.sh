#!/bin/bash

# updater/installer script for moonleaf transition

echo "[*] begin moonleaf transition process"

echo "[+] checking latest version of moonleaf..."
LATEST=$(curl -s https://raw.githubusercontent.com/naomisphere/moonleaf/main/latest)

if [ -z "$LATEST" ]; then
    echo "[!] Error: Could not fetch latest version info."
    exit 1
fi
echo "[>] Latest version found: $LATEST"

CURRENT="$1"
echo "[+] Current version detected: ${CURRENT:-none/macpaper}"

if [ "$LATEST" != "$CURRENT" ]; then
    echo "[*] Update required. Preparing download environment..."
    
    C_TMPDIR="$HOME/.moonleaf_tmp"
    echo "[+] Creating temporary directory at $C_TMPDIR"
    mkdir -p "$C_TMPDIR"

    LATEST_URL="https://github.com/naomisphere/moonleaf/releases/download/$LATEST/moonleaf.dmg"
    DMG_PATH="$C_TMPDIR/moonleaf.dmg"

    echo "[+] Downloading moonleaf $LATEST from GitHub..."
    echo "[>] URL: $LATEST_URL"
    curl -L -# -o "$DMG_PATH" "$LATEST_URL"

    if [ ! -f "$DMG_PATH" ]; then
        echo "[!] Error: Download failed."
        exit 1
    fi
    echo "[>] Download complete."

    VOLUME_NAME="moonleaf"

    echo "[+] Mounting disk image..."
    if [ -d "/Volumes/$VOLUME_NAME" ]; then
        echo "[!] Volume already exists. Forcing detach..."
        hdiutil detach "/Volumes/$VOLUME_NAME" -force
    fi

    hdiutil attach "$DMG_PATH" -nobrowse -quiet
    echo "[>] Disk image mounted."

    echo "[+] Installing moonleaf to /Applications..."
    cp -rf "/Volumes/$VOLUME_NAME/moonleaf.app" "/Applications/moonleaf.app"
    echo "[>] Installation successful."
    
    echo "[+] Cleaning up..."
    hdiutil detach "/Volumes/$VOLUME_NAME" -quiet
    rm -rf "$C_TMPDIR"
    echo "[>] Cleanup complete."

    echo "=========================================="
    echo " done: moonleaf has been installed."
    echo "=========================================="
    echo "if this installer fails to delete itself, you can delete it manually"
else
    echo "[*] already on the latest version."
fi

exit 0