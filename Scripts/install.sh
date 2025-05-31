#!/bin/bash

# Installation script for RazerControlMac
set -e

echo "🚀 Installing RazerControlMac..."

# Check if we're in the right directory
if [ ! -f "Makefile" ]; then
    echo "❌ Error: Please run this script from the RazerControlMac directory"
    exit 1
fi

# Check if build exists
if [ ! -d "build/RazerControl.app" ]; then
    echo "📦 Building application first..."
    make clean && make
fi

# Install the app
echo "📱 Installing RazerControl.app to /Applications..."
if [ -d "/Applications/RazerControl.app" ]; then
    echo "🗑️  Removing existing installation..."
    rm -rf "/Applications/RazerControl.app"
fi

cp -r build/RazerControl.app /Applications/
echo "✅ App installed to /Applications/RazerControl.app"

# Install CLI tool
echo "💻 Installing razerctl command-line tool..."
if [ -f "/usr/local/bin/razerctl" ]; then
    echo "🗑️  Removing existing CLI tool..."
    sudo rm -f /usr/local/bin/razerctl
fi

sudo cp build/razerctl /usr/local/bin/
sudo chmod +x /usr/local/bin/razerctl
echo "✅ CLI tool installed to /usr/local/bin/razerctl"

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📱 You can now launch 'RazerControl' from Applications"
echo "💻 Or use the command line: razerctl --help"
echo ""
echo "📖 For more information, see README.md" 