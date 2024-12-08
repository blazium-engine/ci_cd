#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Log function for structured output
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

# Ensure the base directory exists
DEPS_DIR="/root/deps"
log "### Ensuring dependencies directory exists: $DEPS_DIR"
mkdir -p "$DEPS_DIR"

# macOS needs MoltenVK
if [ ! -d "$DEPS_DIR/moltenvk" ]; then
    log "### Missing MoltenVK for macOS, downloading it."
    mkdir -p "$DEPS_DIR/moltenvk"
    pushd "$DEPS_DIR/moltenvk" > /dev/null
    curl -L -o moltenvk.tar https://github.com/godotengine/moltenvk-osxcross/releases/download/vulkan-sdk-1.3.283.0-2/MoltenVK-all.tar
    tar xf moltenvk.tar && rm -f moltenvk.tar
    mv MoltenVK/MoltenVK/include/ MoltenVK/
    mv MoltenVK/MoltenVK/static/MoltenVK.xcframework/ MoltenVK/
    popd > /dev/null
    log "MoltenVK downloaded and extracted successfully."
else
    log "MoltenVK already exists. Skipping download."
fi

# Windows and macOS need ANGLE
if [ ! -d "$DEPS_DIR/angle" ]; then
    log "### Missing ANGLE libraries, downloading them."
    mkdir -p "$DEPS_DIR/angle"
    pushd "$DEPS_DIR/angle" > /dev/null
    base_url="https://github.com/godotengine/godot-angle-static/releases/download/chromium%2F6601.2/godot-angle-static"
    curl -L -o windows_arm64.zip "$base_url-arm64-llvm-release.zip"
    curl -L -o windows_x86_64.zip "$base_url-x86_64-gcc-release.zip"
    curl -L -o windows_x86_32.zip "$base_url-x86_32-gcc-release.zip"
    curl -L -o macos_arm64.zip "$base_url-arm64-macos-release.zip"
    curl -L -o macos_x86_64.zip "$base_url-x86_64-macos-release.zip"
    unzip -o windows_arm64.zip && rm -f windows_arm64.zip
    unzip -o windows_x86_64.zip && rm -f windows_x86_64.zip
    unzip -o windows_x86_32.zip && rm -f windows_x86_32.zip
    unzip -o macos_arm64.zip && rm -f macos_arm64.zip
    unzip -o macos_x86_64.zip && rm -f macos_x86_64.zip
    popd > /dev/null
    log "ANGLE libraries downloaded and extracted successfully."
else
    log "ANGLE libraries already exist. Skipping download."
fi

# Mesa/NIR libraries
if [ ! -d "$DEPS_DIR/mesa" ]; then
    log "### Missing Mesa/NIR libraries, downloading them."
    mkdir -p "$DEPS_DIR/mesa"
    pushd "$DEPS_DIR/mesa" > /dev/null
    curl -L -o mesa_arm64.zip https://github.com/godotengine/godot-nir-static/releases/download/23.1.9-1/godot-nir-static-arm64-llvm-release.zip
    curl -L -o mesa_x86_64.zip https://github.com/godotengine/godot-nir-static/releases/download/23.1.9-1/godot-nir-static-x86_64-gcc-release.zip
    curl -L -o mesa_x86_32.zip https://github.com/godotengine/godot-nir-static/releases/download/23.1.9-1/godot-nir-static-x86_32-gcc-release.zip
    unzip -o mesa_arm64.zip && rm -f mesa_arm64.zip
    unzip -o mesa_x86_64.zip && rm -f mesa_x86_64.zip
    unzip -o mesa_x86_32.zip && rm -f mesa_x86_32.zip
    popd > /dev/null
    log "Mesa/NIR libraries downloaded and extracted successfully."
else
    log "Mesa/NIR libraries already exist. Skipping download."
fi

# Swappy libraries
if [ ! -d "$DEPS_DIR/swappy" ]; then
    log "### Missing Swappy libraries, downloading them."
    mkdir -p "$DEPS_DIR/swappy"
    pushd "$DEPS_DIR/swappy" > /dev/null
    curl -L -O https://github.com/darksylinc/godot-swappy/releases/download/v2023.3.0.0/godot-swappy.7z
    7z x godot-swappy.7z && rm godot-swappy.7z
    popd > /dev/null
    log "Swappy libraries downloaded and extracted successfully."
else
    log "Swappy libraries already exist. Skipping download."
fi

log "### Dependency download and setup completed successfully!"
