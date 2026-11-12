#!/bin/zsh
set -eu
cd "${0:A:h:h}"
swift build -c release
app="dist/What's My Colour.app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/WhatsMyColour "$app/Contents/MacOS/WhatsMyColour"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>WhatsMyColour</string>
<key>CFBundleIdentifier</key><string>com.whatsmycolour.app</string>
<key>CFBundleName</key><string>What's My Colour</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
# Keep the designated requirement stable so local rebuilds preserve TCC grants.
codesign --force --sign - --identifier com.whatsmycolour.app \
  --requirements '=designated => identifier "com.whatsmycolour.app"' "$app"
echo "Built $app"
