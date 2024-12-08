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
IOS_SDK=${IOS_SDK:-"17.5"}  # Default to SDK version 17.5 if not provided
CCTOOLS_REPO="https://github.com/tpoechtrager/cctools-port"
CCTOOLS_COMMIT="a98286d858210b209395624477533c0bde05556a"
IOSCROSS_ROOT="/root/ioscross"
FILES_DIR="/root/files"

log "### Starting iOS Cross Toolchain Setup"

# Ensure the files directory exists
log "### Ensuring directories exist: $FILES_DIR and $IOSCROSS_ROOT"
mkdir -p "$FILES_DIR"
mkdir -p "$IOSCROSS_ROOT"

# Clone and set up cctools-port
log "### Cloning cctools-port repository"
git clone --progress "$CCTOOLS_REPO" /root/cctools-port
cd /root/cctools-port
log "Checking out commit $CCTOOLS_COMMIT"
git checkout "$CCTOOLS_COMMIT"

# Build arm64 device toolchain
log "### Building arm64 device toolchain"
usage_examples/ios_toolchain/build.sh "$FILES_DIR/iPhoneOS${IOS_SDK}.sdk.tar.xz" arm64
mkdir -p "$IOSCROSS_ROOT/arm64"
mv usage_examples/ios_toolchain/target/* "$IOSCROSS_ROOT/arm64"
mkdir -p "$IOSCROSS_ROOT/arm64/usr"
ln -s "$IOSCROSS_ROOT/arm64/bin" "$IOSCROSS_ROOT/arm64/usr/bin"
log "arm64 device toolchain built and installed."

# Prepare for simulator builds (adjust WRAPPER_SDKDIR)
log "### Preparing for simulator builds"
sed -i '/WRAPPER_SDKDIR/s/iPhoneOS/iPhoneSimulator/' usage_examples/ios_toolchain/build.sh

# Build arm64 simulator toolchain
log "### Building arm64 simulator toolchain"
usage_examples/ios_toolchain/build.sh "$FILES_DIR/iPhoneSimulator${IOS_SDK}.sdk.tar.xz" arm64
mkdir -p "$IOSCROSS_ROOT/arm64_sim"
mv usage_examples/ios_toolchain/target/* "$IOSCROSS_ROOT/arm64_sim"
mkdir -p "$IOSCROSS_ROOT/arm64_sim/usr"
ln -s "$IOSCROSS_ROOT/arm64_sim/bin" "$IOSCROSS_ROOT/arm64_sim/usr/bin"
log "arm64 simulator toolchain built and installed."

# Build x86_64 simulator toolchain
log "### Building x86_64 simulator toolchain"
sed -i 's/^TRIPLE=.*/TRIPLE="x86_64-apple-darwin11"/' usage_examples/ios_toolchain/build.sh
usage_examples/ios_toolchain/build.sh "$FILES_DIR/iPhoneSimulator${IOS_SDK}.sdk.tar.xz" x86_64
mkdir -p "$IOSCROSS_ROOT/x86_64_sim"
mv usage_examples/ios_toolchain/target/* "$IOSCROSS_ROOT/x86_64_sim"
mkdir -p "$IOSCROSS_ROOT/x86_64_sim/usr"
ln -s "$IOSCROSS_ROOT/x86_64_sim/bin" "$IOSCROSS_ROOT/x86_64_sim/usr/bin"
log "x86_64 simulator toolchain built and installed."

# Cleanup
log "### Cleaning up cctools-port repository"
cd /root
rm -rf /root/cctools-port

# Environment Variables
log "### Setting environment variables"
export OSXCROSS_IOS=not_nothing
export IOSCROSS_ROOT="$IOSCROSS_ROOT"
export PATH="$IOSCROSS_ROOT/arm64/bin:$IOSCROSS_ROOT/arm64_sim/bin:$IOSCROSS_ROOT/x86_64_sim/bin:$PATH"
log "Environment variables set:
- OSXCROSS_IOS=$OSXCROSS_IOS
- IOSCROSS_ROOT=$IOSCROSS_ROOT
- PATH=$PATH"

log "### iOS Cross Toolchain Setup Completed Successfully!"
