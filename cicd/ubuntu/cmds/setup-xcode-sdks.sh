#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Log function for structured debug output
log() {
    local message="$1"
    if [[ -n "$GITHUB_ACTIONS" ]]; then
        echo "$message" >> "$GITHUB_STEP_SUMMARY"
    fi
    echo "$message"
}

# Detect if running on a GitHub Actions runner
if [[ -n "$GITHUB_ACTIONS" ]]; then
    log "### Running on a GitHub Actions runner"
    log "Debug information will be written to GITHUB_STEP_SUMMARY."
else
    log "### Not running on a GitHub Actions runner"
    log "Debug information will only appear in the terminal."
fi

# Variables
PBZX_REPO="https://github.com/nrosenstein-stuff/pbzx"
PBZX_COMMIT="bf536e167f2e514866f91d7baa0df1dff5a13711"
XCODE_SDKV=${XCODE_SDKV:-"15.4"}  # Default Xcode version
OSX_SDKV=${OSX_SDKV:-"14.5"}      # Default macOS SDK version
IOS_SDKV=${IOS_SDKV:-"17.5"}      # Default iOS SDK version
FILES_DIR="/root/files"
XCODE_DIR="/root/xcode"
PBZX_DIR="/root/pbzx"

log "### Starting Xcode SDK Packaging Script"

# Ensure the files directory exists
log "### Ensuring files directory exists: $FILES_DIR"
mkdir -p "$FILES_DIR"

# Step 1: Clone and build pbzx
log "### Cloning pbzx repository"
git clone --progress "$PBZX_REPO" "$PBZX_DIR"
cd "$PBZX_DIR"
log "Checking out commit $PBZX_COMMIT"
git checkout "$PBZX_COMMIT"

log "### Building pbzx"
clang -O3 -llzma -lxar -I /usr/local/include pbzx.c -o pbzx

# Step 2: Extract Xcode XIP and build SDK tarballs
log "### Extracting Xcode XIP"
mkdir -p "$XCODE_DIR"
cd "$XCODE_DIR"
xar -xf "$FILES_DIR/Xcode_${XCODE_SDKV}.xip"
/root/pbzx/pbzx -n Content | cpio -i

# Step 3: Package macOS SDK
log "### Packaging macOS SDK"
export OSX_SDK="MacOSX${OSX_SDKV}.sdk"
cp -r "Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk" "/tmp/${OSX_SDK}"
cd /tmp
tar -cJf "$FILES_DIR/${OSX_SDK}.tar.xz" "${OSX_SDK}"
rm -rf "${OSX_SDK}"
log "Packaged macOS SDK as ${OSX_SDK}.tar.xz"

# Step 4: Package iPhoneOS SDK
log "### Packaging iPhoneOS SDK"
export IOS_SDK="iPhoneOS${IOS_SDKV}.sdk"
cd "$XCODE_DIR"
cp -r "Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" "/tmp/${IOS_SDK}"
cd /tmp
tar -cJf "$FILES_DIR/${IOS_SDK}.tar.xz" "${IOS_SDK}"
rm -rf "${IOS_SDK}"
log "Packaged iPhoneOS SDK as ${IOS_SDK}.tar.xz"

# Step 5: Package iPhoneSimulator SDK
log "### Packaging iPhoneSimulator SDK"
export IOS_SIMULATOR_SDK="iPhoneSimulator${IOS_SDKV}.sdk"
cd "$XCODE_DIR"
cp -r "Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" "/tmp/${IOS_SIMULATOR_SDK}"
cd /tmp
tar -cJf "$FILES_DIR/${IOS_SIMULATOR_SDK}.tar.xz" "${IOS_SIMULATOR_SDK}"
rm -rf "${IOS_SIMULATOR_SDK}"
log "Packaged iPhoneSimulator SDK as ${IOS_SIMULATOR_SDK}.tar.xz"

# Cleanup
log "### Cleaning up Xcode directory"
rm -rf "$XCODE_DIR"

log "### Xcode SDK Packaging Script Completed Successfully!"
