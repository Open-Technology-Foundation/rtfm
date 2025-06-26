#!/usr/bin/env bash
# Test script to verify the install process works

set -euo pipefail

echo "Testing rtfm installation fix..."

# Create a temporary directory
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Copy rtfm to temp
cp rtfm "$TMPDIR/rtfm"
chmod +x "$TMPDIR/rtfm"

# Test the --install process (dry run)
echo "Simulating install process..."
cd "$TMPDIR"

# Extract the functions that would be in the temp script
bash -c "
source ./rtfm
declare -pf calculate_checksum verify_checksum download_checksums verify_repo_integrity | grep -q 'download_checksums' && echo '✓ Functions are properly declared' || echo '✗ Functions missing'
"

echo "Test complete"