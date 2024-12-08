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
BASE_URL="https://downloads.tuxfamily.org/godotengine/toolchains/linux/2024-01-17"
SDKS=(
    "x86_64-godot-linux-gnu_sdk-buildroot"
    "i686-godot-linux-gnu_sdk-buildroot"
    "aarch64-godot-linux-gnu_sdk-buildroot"
    "arm-godot-linux-gnueabihf_sdk-buildroot"
)
BASE_PATH=${PATH}

log "### Starting Godot SDK Installation Script"

# Function to download, extract, and relocate SDK
install_sdk() {
    local sdk_name=$1
    log "### Processing SDK: $sdk_name"
    
    # Download the SDK archive
    local archive="${sdk_name}.tar.bz2"
    log "Downloading SDK archive: ${BASE_URL}/${archive}"
    if curl -LO "${BASE_URL}/${archive}"; then
        log "Downloaded $archive successfully."
    else
        log "Failed to download $archive from $BASE_URL."
        exit 1
    fi

    # Extract the SDK archive
    log "Extracting SDK archive: $archive"
    if tar xf "${archive}"; then
        log "Extracted $archive successfully."
    else
        log "Failed to extract $archive."
        exit 1
    fi

    # Remove the downloaded archive
    log "Removing SDK archive: $archive"
    rm -f "${archive}"

    # Relocate the SDK
    log "Relocating SDK: $sdk_name"
    cd "${sdk_name}"
    if ./relocate-sdk.sh; then
        log "Relocated $sdk_name successfully."
    else
        log "Failed to relocate $sdk_name."
        exit 1
    fi
    cd /root
}

# Install each SDK
for sdk in "${SDKS[@]}"; do
    install_sdk "$sdk"
done

log "### All Godot SDKs have been installed and relocated successfully!"
