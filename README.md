# Razer-Basilisk-X-HyperSpeed-Driver-For-macos
Razer Basilisk X HyperSpeed Driver For macos

中文版[README.md](./README_cn.md)

Razer Basilisk X HyperSpeed Mouse Control Software for macOS 12+

This project is only available for the Razer Basilisk X HyperSpeed Mouse Driver, and provides an idea for those who want to port from OpenRazer to macOS to port drivers from other devices themselves

Download in [Releases](https://github.com/liu5580/Razer-Basilisk-X-HyperSpeed-Driver-For-macos/releases/tag/V1.0.0)

You can directly run the version of RazerControl.app in the project/build and the command-line tool razerctl, which can be downloaded and run directly, and supports macOS12+

## Self-Build Steps:

### Method 1: Automatic Build and Installation (Recommended)
```bash
cd RazerControlMac
./Scripts/build.sh
./Scripts/install.sh
```

### Method 2: Install manually
1. Build the app:
```bash
make clean && make
```

2. Install the app:
```bash
# Install the GUI application
cp -r build/RazerControl.app /Applications/

# Install the command line tool
sudo cp build/razerctl /usr/local/bin/
sudo chmod +x /usr/local/bin/razerctl
```

## System Requirements

- Operating System: macOS 12.0 (Monterey) or later
- **Hardware**: Razer Basilisk X HyperSpeed Mouse
- **Development Tools** (only required for builds):
- Xcode Command Line Tools
- Clang compiler

## How to use

### Menu bar app

1. **Launch the app**:
- Double-click 'RazerControl.app' from the Applications folder
- The app runs in the background and only shows the icon in the menu bar (not in the Dock)
- Look for the mouse icon in the menu bar

2. Open Settings:
- Left-click on the menu bar icon to open the settings window directly
- Right-click on the menu bar icon to display the options menu (open settings, exit)
- The settings window displays all device controls and information

3. **Background Running**:
- After closing the settings window, the app continues to run in the background
- The app remains available at any time in the menu bar
- Right-click the menu bar icon to exit the app

### Key features

#### DPI control
- Slider adjustment 100-16000 DPI
- Preset button quick settings (400, 800, 1600, 3200, 6400)
- Effective immediately

#### polling rate setting
- Switch between 125Hz/500Hz/1000Hz
- Higher polling rates provide smoother cursor movements, but may use more CPU

#### Battery monitoring
- Real-time battery level display
- Low battery warning



### Command-line tools

```bash
# Set DPI
razerctl dpi 1600

# Set the polling rate
razerctl polling 1000

# Check the battery status
razerctl battery

# Get device information
razerctl info

# View all current settings
razerctl status
```

## Permission settings

### USB device access

1. On first run, you may be asked to grant access to the USB device
2. If the app can't detect the device:
- Go to 'System Preferences' > 'Security & Privacy' > 'Privacy'
- In the list on the left, find 'Input Monitoring' or the relevant permission
- Make sure 'RazerControl' is checked

### Admin privileges

- CLI tool installation requires 'sudo' permissions
- Administrator privileges are not required to run the app

## Troubleshooting

### The device is not detected
1. **Check Connection**: Make sure the mouse is connected via USB (not Bluetooth)
2. System Information: Open 'About This Mac'> 'System Reports' > 'USB' and find the device
3. Reconnect: Unplug and replug the USB receiver
4. Restart App: Quit and restart RazerControl

### The menu bar icon can't be found
1. **Look Carefully**: The menu bar icon may be small, please look carefully
2. Activity Monitor: Check that RazerControl is running in Activity Monitor
3. Restart: Try quitting and restarting the app
4. Launch from Applications Folder: Make sure to launch from the Applications folder

### Build error
1. **Install Development Tools**:
```bash
xcode-select --install
```

2. **Check SDK**:
```bash
xcrun --show-sdk-path
```

3. **Clean up and rebuild**:
```bash
make clean && make
```

### Permission issues
1. **System Preferences** > **Security & Privacy** > **Privacy**
2. Add 'RazerControl.app' to the list of necessary permissions
3. Restart the app

## Technical details

### Supported features
- ✅ DPI Adjustment (100-16000)
- ✅ Polling rate setting (125/500/1000 Hz)
- ✅ Battery level monitoring(the displayed value may be incorrect)
- ✅ Query the firmware version
- ✅ Device serial number query
- ✅ Menu bar integration
- ✅ Running in the background (hide the Dock icon)
- ✅ Custom app icon (transparent mouse icon)
- ✅ Command-line interface
- ✅ Improved device reconnection mechanism

### Known limitations
- Only USB connection mode is supported
- Macro settings are not supported
- Key remapping is not supported

### USB protocol
Based on the openRazer project's USB HID communication protocol:
- Vendor ID: 0x1532 (Razer)
- Product ID: 0x0083 (Basilisk X HyperSpeed)
- Report length: 90 bytes

### Running in the background
- With the LSUIElement configuration, the app is only displayed in the menu bar
- No icons are displayed in the Dock to reduce interface distractions
- Continuous monitoring of device status in the background

## Uninstall

### Uninstall completely
```bash
# Delete the app
rm -rf /Applications/RazerControl.app

# Delete the command line tool
sudo rm -f /usr/local/bin/razerctl

# Delete Preferences (Optional)
rm -rf ~/Library/Preferences/com.razercontrol.macos.*
```

## Get help

1. **View Logs**:
- Application logs: 'Console.app' search for 'RazerControl'
- Syslog: Check for USB-related errors

2. **Frequently Asked Questions**:
- Make sure you're using an official USB receiver
- Try a different USB port

- Check the battery level of the mouse
- If the menu bar icon disappears, restart the app

3. **Report Issues**:
- Collect system information and error logs
- Describe the specific steps to reproduce

## Version information

- **Current Version**: 1.0.0
- **Compatible OS**: macOS 12.0+
- **Supported Devices**: Razer Basilisk X HyperSpeed
- **Updated**: 2025.5.31

<img width="483" alt="iShot_2025-05-31_19 25 47" src="https://github.com/user-attachments/assets/22639216-73ce-4df7-a2c5-bf14fb256f0e" />

---

**Disclaimer**: This is an unofficial tool and is not affiliated with Razer Inc. Use at your own risk. Refer to the openRazer open source project and comply with the open source license, GPL
🈲 Plagiarism and forwarding 🈲 @https://github.com/openrazer/openrazer are strictly prohibited

