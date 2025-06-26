#!/usr/bin/env bash
set -euo pipefail

# Script to update checksums.sha256 file
# Run this before committing changes to ensure checksums are current

declare -r PRG="${0##*/}"
declare -r CHECKSUM_FILE="checksums.sha256"

# Files to include in checksum
declare -a FILES=(
  "rtfm"
  "README.md"
  "LICENSE"
)

main() {
  local -- file
  local -- checksum
  local -i missing=0
  
  # Check if sha256sum is available
  if ! command -v sha256sum >/dev/null; then
    >&2 echo "$PRG: Error: sha256sum command not found"
    exit 1
  fi
  
  # Verify all files exist
  for file in "${FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
      >&2 echo "$PRG: Error: File not found: $file"
      missing=1
    fi
  done
  
  ((missing)) && exit 1
  
  # Generate new checksums file
  {
    echo "# SHA256 checksums for rtfm"
    echo "# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "# Run update-checksums.sh before committing changes"
    echo
    
    for file in "${FILES[@]}"; do
      checksum=$(sha256sum "$file" | cut -d' ' -f1)
      printf "%s  %s\n" "$checksum" "$file"
    done
  } > "$CHECKSUM_FILE"
  
  echo "$PRG: Updated $CHECKSUM_FILE"
  echo "$PRG: Files included:"
  for file in "${FILES[@]}"; do
    echo "  - $file"
  done
}

main "$@"