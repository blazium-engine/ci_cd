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

# Variables
XAR_REPO="https://github.com/mackyle/xar.git"
INSTALL_DIR="/usr/local/src/xar"

log "### Xar Installation Script Started"

# Detect if running on a GitHub Actions runner
if [[ -n "$GITHUB_ACTIONS" ]]; then
    log "GitHub Actions runner detected. Debug output will be written to GITHUB_STEP_SUMMARY."
else
    log "Not running on a GitHub Actions runner. Debug output will only appear in stdout."
fi

# Clone the xar repository
log "### Cloning xar repository"
if [[ ! -d "$INSTALL_DIR" ]]; then
    log "Cloning repository from $XAR_REPO into $INSTALL_DIR"
    git clone "$XAR_REPO" "$INSTALL_DIR"
else
    log "Xar source already exists in $INSTALL_DIR. Skipping clone."
fi

# Navigate to the source directory
log "### Navigating to source directory"
cd "$INSTALL_DIR/xar" || { log "Failed to navigate to $INSTALL_DIR/xar"; exit 1; }

#sed -i '332s/^.*$/AC_CHECK_LIB([crypto], [OPENSSL_init_crypto], , [have_libcrypto="0"])/' configure.ac;

# Check if configure script exists or run autogen.sh
if [[ ! -f ./configure ]]; then
    log "Running autogen.sh to generate configure script..."
    ./autogen.sh
else
    log "Configure script already exists. Skipping autogen.sh."
fi

# Build and install Xar
log "### Configuring build"
./configure

make

make install

# log "### Building all components"
make src_all
make lib_all

# log "### Installing components"
make src_install
make lib_install

# # Optional cleanup
# log "### Cleaning up build artifacts"
# make clean

# Verify installation
log "### Verifying Xar installation"
if xar --version; then
    log "Xar has been installed successfully!"
else
    log "Xar installation failed."
    exit 1
fi

log "### Xar Installation Script Completed Successfully"
