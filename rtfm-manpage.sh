#!/usr/bin/env bash
set -euo pipefail

declare -r SCRIPT_NAME="${0##*/}"
declare -r SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -r README_FILE="${SCRIPT_DIR}/README.md"
declare -r MANPAGE_FILE="${SCRIPT_DIR}/rtfm.1"
declare -r VERSION="1.0.0"

# Function to display usage
usage() {
  cat >&2 <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Generate manpage from README.md for rtfm

Options:
  -i, --install    Install the generated manpage to system location
  -h, --help       Display this help message

Examples:
  ${SCRIPT_NAME}              # Generate rtfm.1 manpage
  ${SCRIPT_NAME} --install    # Generate and install manpage
EOF
}

# Function to check if running with sufficient privileges
can_sudo() {
  if [[ $EUID -eq 0 ]]; then
    return 0
  elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to extract version from rtfm script
get_version() {
  if [[ -f "${SCRIPT_DIR}/rtfm" ]]; then
    grep -oP 'VERSION="\K[^"]+' "${SCRIPT_DIR}/rtfm" 2>/dev/null || echo "$VERSION"
  else
    echo "$VERSION"
  fi
}

# Function to generate manpage from README
generate_manpage() {
  local version
  version=$(get_version)
  
  cat > "$MANPAGE_FILE" <<'EOF'
.\" Manpage for rtfm
.\" Generated from README.md
.TH RTFM 1 "$(date '+%B %Y')" "rtfm ${version}" "User Commands"
.SH NAME
rtfm \- Read The Fucking Manuals
.SH SYNOPSIS
.B rtfm
[\fIOPTIONS\fR] \fIcommand\fR
.SH DESCRIPTION
A Linux command-line utility that searches for documentation about commands across multiple help systems and concatenates the results.
.PP
The
.B rtfm
program is designed to address the problem of efficiently accessing and consolidating documentation for Linux commands from multiple help systems.
.PP
Users often need to refer to various sources of documentation, such as Bash built-in help, man pages, info pages, and TLDR pages.
.B rtfm
searches through all these different documentation sources and combines the results, thus simplifying the process of finding relevant information about commands.
.SH OPTIONS
.TP
.BR \-r ", " \-\-rebuild\-lists
Rebuild command lists for each help source
.TP
.BR \-\-install ", " \-\-update
Install or update rtfm, md2ansi, and tldr from GitHub
.TP
.BR \-v ", " \-\-verbose
Verbose output during operations (default)
.TP
.BR \-q ", " \-\-quiet
Suppress verbose output during install and update operations
.TP
.BR \-V ", " \-\-version
Print version
.TP
.BR \-h ", " \-\-help
Display help message
.SH FEATURES
Searches for command help in the following order:
.RS
.IP \(bu 2
Bash builtin help
.IP \(bu 2
Man pages
.IP \(bu 2
Info pages
.IP \(bu 2
TLDR pages
.RE
.PP
Combines results from all available documentation sources
.PP
Uses markdown formatting with md2ansi support
.PP
Clean pagination with less
.PP
Easy list rebuilding for keeping documentation sources up-to-date
.PP
SHA256 checksum verification for secure updates (requires sha256sum)
.SH INSTALLATION
The easiest way to install rtfm and dependencies is to use the built-in installer:
.PP
.nf
# Download the script
wget https://raw.githubusercontent.com/Open-Technology-Foundation/rtfm/main/rtfm
# Make it executable
chmod +x rtfm
# Install rtfm, md2ansi, and tldr from GitHub
sudo ./rtfm --install
.fi
.PP
Or as a one-liner:
.PP
.nf
wget https://raw.githubusercontent.com/Open-Technology-Foundation/rtfm/main/rtfm && chmod +x rtfm && sudo ./rtfm --install
.fi
.PP
This will automatically install:
.RS
.IP \(bu 2
git (if not already installed)
.IP \(bu 2
rtfm (documentation lookup utility)
.IP \(bu 2
md2ansi (markdown to terminal converter for nicer formatting)
.IP \(bu 2
tldr pages (simplified command documentation and examples)
.RE
.SH UPDATING
To update rtfm:
.PP
.nf
# Update rtfm, md2ansi, and tldr from GitHub
sudo rtfm --update
.fi
.SH EXAMPLES
.TP
.B rtfm rsync
Look up documentation for rsync
.TP
.B rtfm declare
Get help for bash's declare builtin
.TP
.B rtfm coreutils
View comprehensive coreutils documentation
.TP
.B rtfm find
Search for find command usage
.TP
.B rtfm --update
Update rtfm and dependencies
.TP
.B rtfm -r
Rebuild documentation lists
.SH FILES
rtfm searches for documentation in these list files:
.TP
.I builtin.list
Bash builtin commands
.TP
.I man.list
Commands with man pages
.TP
.I info.list
Commands with info pages
.TP
.I tldr.list
Commands with TLDR pages
.PP
Run
.B rtfm --rebuild-lists
to generate or update these files.
.SH SECURITY
The rtfm update mechanism includes SHA256 checksum verification to ensure the integrity of downloaded files. When updating, the script:
.PP
.RS
1. Downloads repositories from GitHub
.br
2. Downloads and verifies checksums (if sha256sum is available)
.br
3. Only installs verified files
.br
4. Automatically rolls back on verification failure
.RE
.PP
To manually verify the integrity of the installation, check the checksums.sha256 file in the repository.
.SS Maintaining Checksums
The checksums.sha256 file must be updated whenever tracked files change. There are three ways to ensure this:
.PP
.RS
1. Manual Update: Run ./update-checksums.sh before committing changes
.br
2. Git Hook: The pre-commit hook automatically updates checksums
.br
3. GitHub Actions: The workflow automatically updates checksums on push
.RE
.SH DEPENDENCIES
.TP
.B bash
For script execution
.TP
.B grep
For searching through documentation
.TP
.B less
For paginated viewing
.TP
.B man
For man page documentation
.TP
.B info
For info page documentation
.TP
.B tldr
For simplified command documentation with examples (installed with --install)
.TP
.B md2ansi
For better formatted output (installed with --install)
.TP
.B git
For installation and update operations (installed with --install)
.TP
.B sha256sum
For checksum verification during updates (optional but recommended)
.SH LICENSE
This project is licensed under the GNU General Public License v3.0
.SH AUTHOR
Open Technology Foundation
.SH SEE ALSO
.BR man (1),
.BR info (1),
.BR help (1),
.BR tldr (1)
EOF
  
  # Replace placeholders with actual values
  sed -i "s/\$(date '+%B %Y')/$(date '+%B %Y')/g" "$MANPAGE_FILE"
  sed -i "s/\${version}/${version}/g" "$MANPAGE_FILE"
  
  echo "Generated manpage: $MANPAGE_FILE"
}

# Function to install manpage
install_manpage() {
  local man_dir="/usr/local/share/man/man1"
  
  if ! can_sudo; then
    echo "Error: Installation requires sudo privileges" >&2
    echo "Please run: sudo ${SCRIPT_NAME} --install" >&2
    exit 1
  fi
  
  # Create man directory if it doesn't exist
  if [[ $EUID -eq 0 ]]; then
    mkdir -p "$man_dir"
  else
    sudo mkdir -p "$man_dir"
  fi
  
  # Copy manpage
  if [[ $EUID -eq 0 ]]; then
    cp "$MANPAGE_FILE" "${man_dir}/rtfm.1"
    chmod 644 "${man_dir}/rtfm.1"
  else
    sudo cp "$MANPAGE_FILE" "${man_dir}/rtfm.1"
    sudo chmod 644 "${man_dir}/rtfm.1"
  fi
  
  # Update man database if mandb is available
  if command -v mandb &>/dev/null; then
    echo "Updating man database..."
    if [[ $EUID -eq 0 ]]; then
      mandb
    else
      sudo mandb
    fi
  fi
  
  echo "Manpage installed to: ${man_dir}/rtfm.1"
  echo "You can now use: man rtfm"
}

# Main function
main() {
  local install=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--install)
        install=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
  
  # Check if README exists
  if [[ ! -f "$README_FILE" ]]; then
    echo "Error: README.md not found at $README_FILE" >&2
    exit 1
  fi
  
  # Generate manpage
  generate_manpage
  
  # Install if requested
  if [[ "$install" == true ]]; then
    install_manpage
  fi
}

# Execute main function
main "$@"

#fin