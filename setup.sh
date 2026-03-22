#!/bin/bash
# FocusBrick Xcode Project Setup
# Run this on your Mac from the repo root: ./setup.sh

set -e

echo "=== FocusBrick Project Setup ==="
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: Xcode is not installed. Install it from the App Store first."
    exit 1
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install XcodeGen if not present
if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen..."
    brew install xcodegen
else
    echo "XcodeGen already installed."
fi

# Create Assets.xcassets if it doesn't exist
ASSETS_DIR="FocusBrick/Assets.xcassets"
if [ ! -d "$ASSETS_DIR" ]; then
    echo "Creating Assets.xcassets..."
    mkdir -p "$ASSETS_DIR/AppIcon.appiconset"
    cat > "$ASSETS_DIR/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    cat > "$ASSETS_DIR/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
fi

# Generate the Xcode project
echo ""
echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Open FocusBrick.xcodeproj"
echo "  2. Select your Team under Signing & Capabilities for ALL 4 targets"
echo "  3. Build with Cmd+B (use a physical iPhone for full functionality)"
echo ""
echo "Note: Family Controls requires a real device and an Apple Developer"
echo "account with the Family Controls entitlement for distribution builds."
