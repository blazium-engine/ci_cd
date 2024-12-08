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
ANDROID_SDK_ROOT="/root/sdk"
ANDROID_NDK_VERSION="23.2.8568313"
CMDLINETOOLS="commandlinetools-linux-11076708_latest.zip"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/${CMDLINETOOLS}"
SDK_MANAGER="${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager"

log "### Starting Android SDK and NDK Setup Script"

# Create Android SDK directory
log "### Creating Android SDK directory: ${ANDROID_SDK_ROOT}"
mkdir -p "${ANDROID_SDK_ROOT}"
cd "${ANDROID_SDK_ROOT}"

# Download command line tools
log "### Downloading command line tools from ${CMDLINE_TOOLS_URL}"
if curl -LO "${CMDLINE_TOOLS_URL}"; then
    log "Command line tools downloaded successfully."
else
    log "Failed to download command line tools."
    exit 1
fi

# Extract command line tools
log "### Extracting command line tools"
if unzip "${CMDLINETOOLS}"; then
    log "Command line tools extracted successfully."
else
    log "Failed to extract command line tools."
    exit 1
fi
rm -f "${CMDLINETOOLS}"

# Accept licenses
log "### Accepting Android SDK licenses"
if yes | ${SDK_MANAGER} --sdk_root="${ANDROID_SDK_ROOT}" --licenses; then
    log "Licenses accepted successfully."
else
    log "Failed to accept licenses."
    exit 1
fi

# Install required packages
log "### Installing required Android SDK components"
if ${SDK_MANAGER} --sdk_root="${ANDROID_SDK_ROOT}" \
    "ndk;${ANDROID_NDK_VERSION}" \
    "cmdline-tools;latest" \
    "build-tools;34.0.0" \
    "platforms;android-34" \
    "cmake;3.22.1"; then
    log "Android SDK components installed successfully."
else
    log "Failed to install required Android SDK components."
    exit 1
fi

# Environment Variables
log "### Setting environment variables"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
export ANDROID_NDK_VERSION="${ANDROID_NDK_VERSION}"
export ANDROID_NDK_ROOT="${ANDROID_SDK_ROOT}/ndk/${ANDROID_NDK_VERSION}"
log "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}"
log "ANDROID_NDK_VERSION=${ANDROID_NDK_VERSION}"
log "ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}"

log "### Android SDK and NDK setup completed successfully!"
