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

# Variables
OSX_SDK=${OSX_SDK:-"14.5"} # Default SDK version if not provided
CLANG_VERSION="16.0.0"
INSTALLPREFIX="/usr"
OSXCROSS_DIR="/root/osxcross"
FILES_DIR="/root/files"

log "### Starting osxcross Setup Script"

# Step 1: Clone the osxcross repository
log "### Cloning osxcross repository"
git clone --progress https://github.com/tpoechtrager/osxcross $OSXCROSS_DIR

# Step 2: Checkout to the specific commit
log "### Checking out to commit ff8d100f3f026b4ffbe4ce96d8aac4ce06f1278b"
cd $OSXCROSS_DIR
git checkout ff8d100f3f026b4ffbe4ce96d8aac4ce06f1278b

# Step 3: Download and apply the patch
log "### Applying patch 415"
curl -LO https://github.com/tpoechtrager/osxcross/pull/415.patch
git apply 415.patch

# Step 4: Link the macOS SDK tarball
log "### Linking the macOS SDK tarball"
mkdir -p "$FILES_DIR"
ln -sf "$FILES_DIR/MacOSX${OSX_SDK}.sdk.tar.xz" "$OSXCROSS_DIR/tarballs"

# Step 5: Set environment variables
log "### Setting environment variables for the build"
export UNATTENDED=1
export SDK_VERSION=${OSX_SDK}

# Step 6: Build Apple Clang
log "### Building Apple Clang with LLVM version $CLANG_VERSION"
ENABLE_CLANG_INSTALL=1 CLANG_VERSION=$CLANG_VERSION INSTALLPREFIX=$INSTALLPREFIX ./build_apple_clang.sh

# Step 7: Build osxcross and compiler_rt
log "### Building osxcross"
./build.sh
log "### Building compiler_rt"
./build_compiler_rt.sh

# Step 8: Clean up build artifacts
log "### Cleaning up build artifacts"
rm -rf "$OSXCROSS_DIR/build"

# Step 9: Set environment variables for osxcross
log "### Setting environment variables for osxcross"
export OSXCROSS_ROOT=$OSXCROSS_DIR
export PATH="$OSXCROSS_DIR/target/bin:$PATH"
log "OSXCROSS_ROOT=$OSXCROSS_ROOT"
log "PATH=$PATH"

log "### osxcross Setup Completed Successfully!"
