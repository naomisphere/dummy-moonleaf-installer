#!/bin/bash

APP_NAME="macpaper"
BINARY_NAME="macpaper"

echo "[*] Cleaning up..."
rm -rf "${APP_NAME}.app"
rm -f "${BINARY_NAME}"

echo "[*] Compiling dummy.swift for arm64..."
swiftc dummy.swift -O -target arm64-apple-macosx12.0 -o "${BINARY_NAME}_arm64"
echo "[*] Compiling dummy.swift for x86_64..."
swiftc dummy.swift -O -target x86_64-apple-macosx12.0 -o "${BINARY_NAME}_x86_64"

echo "[*] Creating Universal Binary..."
lipo -create -output "${BINARY_NAME}" "${BINARY_NAME}_arm64" "${BINARY_NAME}_x86_64"
rm "${BINARY_NAME}_arm64" "${BINARY_NAME}_x86_64"

if [ $? -ne 0 ]; then
    echo "[!] Compilation failed."
    exit 1
fi

echo "[*] Creating App Bundle structure..."
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"

echo "[*] Moving binary and resources..."
mv "${BINARY_NAME}" "${APP_NAME}.app/Contents/MacOS/${BINARY_NAME}"
cp updater.sh "${APP_NAME}.app/Contents/Resources/"
cp moonleaf.png "${APP_NAME}.app/Contents/Resources/"
cp macpaper.icns "${APP_NAME}.app/Contents/Resources/"
cp Comfortaa-*.ttf "${APP_NAME}.app/Contents/Resources/"
chmod +x "${APP_NAME}.app/Contents/Resources/updater.sh"


echo "[*] Creating Info.plist..."
cat <<EOF > "${APP_NAME}.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${BINARY_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>macpaper.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.moonleaf.payloader</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>ATSApplicationFontsPath</key>
    <string>.</string>
</dict>
</plist>
EOF


echo "[✔] Build complete: ${APP_NAME}.app"
echo "[*] To run: open ${APP_NAME}.app"
