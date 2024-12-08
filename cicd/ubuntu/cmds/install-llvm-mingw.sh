#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log messages
log() {
    local message="$1"
    if [[ -n "$GITHUB_ACTIONS" ]]; then
        echo "$message" >> "$GITHUB_STEP_SUMMARY"
    fi
    echo "$message"
}

# Detect if running on a GitHub Actions runner
if [[ -n "$GITHUB_ACTIONS" ]]; then
    log "## GitHub Actions Runner Detected"
    log "Debugging enabled. Writing logs to GITHUB_STEP_SUMMARY."
else
    echo "Not running on a GitHub Actions runner. Logs will only appear in stdout."
fi

# Navigate to /root
log "### Navigating to /root directory"
cd /root || { log "Failed to navigate to /root"; exit 1; }

# Define variables
log "### Defining variables"
URL="https://github.com/mstorsjo/llvm-mingw/releases/download/20240619/llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64.tar.xz"
ARCHIVE="llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64.tar.xz"
EXTRACTED_DIR="llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64"
DEST_DIR="/root/llvm-mingw"

log "URL: $URL"
log "ARCHIVE: $ARCHIVE"
log "EXTRACTED_DIR: $EXTRACTED_DIR"
log "DEST_DIR: $DEST_DIR"

# Download the archive
log "### Downloading archive from $URL"
curl -LO "$URL"
log "Archive downloaded successfully."

# Extract the archive
log "### Extracting archive $ARCHIVE"
tar xf "$ARCHIVE"
log "Archive extracted successfully."

# Remove the archive
log "### Removing archive $ARCHIVE"
rm -f "$ARCHIVE"
log "Archive removed successfully."

# Move the extracted folder to the desired location
log "### Moving extracted directory to $DEST_DIR"
mv -f "$EXTRACTED_DIR" "$DEST_DIR"
log "Directory moved successfully."

# Confirmation message
log "### llvm-mingw Installation Complete"
log "llvm-mingw has been successfully installed to $DEST_DIR"

# Exit cleanly
log "Script execution completed successfully."
