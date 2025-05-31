#!/bin/bash

# Build script for RazerControlMac
# This script builds the macOS application for controlling Razer Basilisk X HyperSpeed

set -e  # Exit on error

echo "🔨 Building RazerControlMac..."

# Check for Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo "❌ Error: Xcode Command Line Tools not found"
    echo "Please install them by running: xcode-select --install"
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
make clean

# Build the application
echo "🏗️  Building application and CLI tool..."
make all

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📁 Application built at: build/RazerControl.app"
    echo "🖥️  CLI tool built at: build/razerctl"
    echo ""
    echo "To install:"
    echo "  sudo make install"
    echo ""
    echo "Or manually:"
    echo "  cp -r build/RazerControl.app /Applications/"
    echo "  sudo cp build/razerctl /usr/local/bin/"
else
    echo "❌ Build failed!"
    exit 1
fi 