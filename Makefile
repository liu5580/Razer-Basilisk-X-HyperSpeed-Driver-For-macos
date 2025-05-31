# Makefile for RazerControlMac
# Build configuration for macOS Razer Control Application

CC = clang
OBJC = clang
SWIFT = swiftc
CFLAGS = -Wall -O2 -fPIC
OBJCFLAGS = -fobjc-arc -framework Foundation -framework IOKit
SWIFTFLAGS = -framework SwiftUI -framework Combine -parse-as-library

# Directories
SRC_DIR = src
INC_DIR = include
BUILD_DIR = build
RESOURCES_DIR = Resources
APP_NAME = RazerControl.app
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME)

# Source files
C_SOURCES = $(SRC_DIR)/RazerUSBProtocol.c
OBJC_SOURCES = $(SRC_DIR)/RazerDeviceManager.m
SWIFT_SOURCES = $(SRC_DIR)/RazerControlApp.swift
CLI_SOURCES = $(SRC_DIR)/razerctl.m

# Object files
C_OBJECTS = $(BUILD_DIR)/RazerUSBProtocol.o
OBJC_OBJECTS = $(BUILD_DIR)/RazerDeviceManager.o

# Icon files
APP_ICON = $(RESOURCES_DIR)/AppIcon.icns

# Targets
.PHONY: all clean run cli install icon

all: icon $(APP_BUNDLE) cli

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(C_OBJECTS): $(C_SOURCES) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I$(INC_DIR) -c $< -o $@

$(OBJC_OBJECTS): $(OBJC_SOURCES) | $(BUILD_DIR)
	$(OBJC) $(OBJCFLAGS) -I$(INC_DIR) -c $< -o $@

icon:
	@if [ ! -f $(APP_ICON) ]; then \
		echo "Creating custom app icon..."; \
		python3 Scripts/create_custom_icon.py; \
	fi

$(APP_BUNDLE): $(C_OBJECTS) $(OBJC_OBJECTS) $(SWIFT_SOURCES) | $(BUILD_DIR)
	# Create app bundle structure
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	
	# Build the executable
	$(SWIFT) $(SWIFTFLAGS) \
		-import-objc-header $(INC_DIR)/RazerControlMac-Bridging-Header.h \
		-I$(INC_DIR) \
		-framework Foundation \
		-framework IOKit \
		$(SWIFT_SOURCES) \
		$(C_OBJECTS) \
		$(OBJC_OBJECTS) \
		-o $(APP_BUNDLE)/Contents/MacOS/RazerControl
	
	# Copy app icon if it exists
	@if [ -f $(APP_ICON) ]; then \
		cp $(APP_ICON) $(APP_BUNDLE)/Contents/Resources/; \
		echo "✅ Copied app icon"; \
	fi
	
	# Create Info.plist
	@echo "Creating Info.plist..."
	@/usr/libexec/PlistBuddy -c "Add :CFBundleName string 'RazerControl'" $(APP_BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string 'com.razercontrol.macos'" $(APP_BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string '1.0.0'" $(APP_BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string 'APPL'" $(APP_BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string 'RazerControl'" $(APP_BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string '12.0'" $(APP_BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true" $(APP_BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :LSApplicationCategoryType string 'public.app-category.utilities'" $(APP_BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string 'Copyright © 2024 RazerControl. All rights reserved.'" $(APP_BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" $(APP_BUNDLE)/Contents/Info.plist
	@if [ -f $(APP_ICON) ]; then \
		/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string 'AppIcon'" $(APP_BUNDLE)/Contents/Info.plist; \
		echo "✅ Added icon reference to Info.plist"; \
	fi
	@echo "✅ Added LSUIElement=true to hide dock icon"

cli: $(C_OBJECTS) $(OBJC_OBJECTS) $(CLI_SOURCES) | $(BUILD_DIR)
	$(OBJC) $(OBJCFLAGS) \
		-I$(INC_DIR) \
		$(CLI_SOURCES) \
		$(C_OBJECTS) \
		$(OBJC_OBJECTS) \
		-o $(BUILD_DIR)/razerctl
	@echo "CLI tool built: $(BUILD_DIR)/razerctl"

install: all
	@echo "Installing RazerControl.app to /Applications..."
	@cp -r $(APP_BUNDLE) /Applications/
	@echo "Installing razerctl to /usr/local/bin..."
	@sudo cp $(BUILD_DIR)/razerctl /usr/local/bin/
	@echo "Installation complete!"

clean:
	rm -rf $(BUILD_DIR)

run: all
	open $(APP_BUNDLE)

# Alternative build method using xcodebuild (if Xcode project exists)
xcode-build:
	xcodebuild -project RazerControlMac.xcodeproj -scheme RazerControl -configuration Release build 