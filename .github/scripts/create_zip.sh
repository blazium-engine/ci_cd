#!/usr/bin/env bash
# Create a ZIP archive with 7-Zip (DEFLATE, max compression).
# Keeps standard ZIP format for OS-native extraction (not native .7z).
#
# Usage: create_zip.sh <archive_path> <path...>
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <archive_path> <path...>" >&2
  exit 2
fi

ARCHIVE="$1"
shift

SEVENZ=""
if command -v 7z >/dev/null 2>&1; then
  SEVENZ="7z"
elif command -v 7za >/dev/null 2>&1; then
  SEVENZ="7za"
else
  echo "Error: 7z/7za not found on PATH. Install p7zip-full (Linux) or sevenzip (macOS/Homebrew)." >&2
  exit 1
fi

# Remove existing archive so 7z does not merge/update stale entries.
rm -f "$ARCHIVE"

"$SEVENZ" a -tzip -bso0 -bd -mx=9 "$ARCHIVE" "$@"
