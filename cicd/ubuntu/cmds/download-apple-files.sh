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
FILES_DIR="/root/files"
URLS=(
    "https://cdn.blazium.app/pipeline/MacOSX14.5.sdk.tar.xz"
    "https://cdn.blazium.app/pipeline/Xcode_15.4.xip"
    "https://cdn.blazium.app/pipeline/iPhoneOS17.5.sdk.tar.xz"
    "https://cdn.blazium.app/pipeline/iPhoneSimulator17.5.sdk.tar.xz"
)

log "### Starting File Download Script"

# Ensure the files directory exists
log "### Ensuring files directory exists: $FILES_DIR"
mkdir -p "$FILES_DIR"

# Download each file
for url in "${URLS[@]}"; do
    file_name=$(basename "$url")
    destination="$FILES_DIR/$file_name"
    log "### Downloading $file_name to $destination"
    
    if curl -L -o "$destination" "$url"; then
        log "Downloaded $file_name successfully."
    else
        log "Failed to download $file_name from $url."
        exit 1
    fi
done

log "### All files have been downloaded to $FILES_DIR"
log "### File Download Script Completed Successfully"
