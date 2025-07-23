# PURPOSE-FUNCTIONALITY-USAGE

## Purpose

**rtfm** (Read The Fucking Manuals) is a unified documentation lookup tool for Linux commands. It solves the common problem of fragmented documentation sources by consolidating help information from multiple systems into a single, easy-to-use interface.

### Problem Solved
- Eliminates the need to remember which documentation system has information for a specific command
- Saves time by aggregating all available documentation in one place
- Provides comprehensive help by combining different documentation perspectives (builtin help, man pages, info pages, and simplified TLDR examples)

### Target Audience
- Linux system administrators
- Developers working in command-line environments
- DevOps engineers
- Anyone who frequently uses Linux terminal commands

## Functionality

### Core Features

1. **Multi-Source Documentation Search**
   - Searches in order: Bash builtins → Man pages → Info pages → TLDR pages
   - Concatenates all found documentation with clear section breaks
   - Uses pre-built list files for fast lookups (O(1) performance)

2. **Security-Focused Installation**
   - SHA256 checksum verification for all downloaded files
   - Automatic rollback on verification failure
   - Input validation to prevent command injection

3. **Self-Updating System**
   - Built-in installer fetches from GitHub repositories
   - Updates rtfm itself, md2ansi (markdown formatter), and tldr pages
   - Maintains list files for efficient searching

4. **List Management**
   - Pre-generates lists of available commands from each documentation source
   - `--rebuild-lists` option to refresh documentation indices
   - Automatic list rebuilding after updates

### Key Components

- **rtfm**: Main executable script (rtfm:1-442)
- **List Files**: Pre-built indices for fast lookups
  - `builtin.list`: 75 Bash builtin commands
  - `man.list`: 2,848 commands with man pages
  - `info.list`: 32 GNU info documents
  - `tldr.list`: 4,900 simplified command examples
- **update-checksums.sh**: Maintains file integrity checksums

### Technical Implementation

- Written in Bash with defensive programming practices
- Uses `set -euo pipefail` for robust error handling
- Validates all user input to prevent security issues
- Supports both verbose and quiet operation modes
- Integrates with `less` for paginated viewing
- Optional `md2ansi` integration for enhanced markdown rendering

## Usage

### Basic Command Lookup
```bash
rtfm <command>
```

### Common Examples
```bash
# Look up rsync documentation
rtfm rsync

# Get help for bash's declare builtin
rtfm declare

# View comprehensive coreutils documentation
rtfm coreutils

# Search for find command usage
rtfm find
```

### Administrative Operations

#### Installation
```bash
# One-liner installation
wget https://raw.githubusercontent.com/Open-Technology-Foundation/rtfm/main/rtfm && chmod +x rtfm && sudo ./rtfm --install
```

#### Updates
```bash
# Update rtfm and all dependencies
sudo rtfm --update
```

#### Maintenance
```bash
# Rebuild documentation lists (e.g., after installing new packages)
sudo rtfm --rebuild-lists

# Check version
rtfm --version

# View help
rtfm --help
```

### Options
- `-r, --rebuild-lists`: Rebuild command lists from documentation sources
- `--install, --update`: Install or update rtfm and dependencies
- `-v, --verbose`: Verbose output (default)
- `-q, --quiet`: Suppress verbose messages
- `-V, --version`: Display version information
- `-h, --help`: Show help message

### Workflow Integration

1. **For Daily Use**: Replace separate lookups of `man`, `info`, `help`, and `tldr` with a single `rtfm` command
2. **For System Setup**: Use `--install` on new systems to quickly set up comprehensive documentation
3. **For Package Management**: Run `--rebuild-lists` after installing new software to index new documentation
4. **For Offline Work**: All documentation is stored locally after installation

## Dependencies

### Required
- **bash**: Script execution environment
- **grep**: Searching through lists
- **less**: Paginated viewing
- **man**: Man page system
- **info**: GNU info system

### Optional (Installed Automatically)
- **git**: For installation/updates
- **tldr**: Simplified command examples
- **md2ansi**: Enhanced markdown formatting
- **sha256sum**: Checksum verification (recommended)

## Performance Characteristics

- **Fast lookups**: O(1) using pre-built list files with grep
- **Minimal overhead**: Simple bash script with efficient command checking
- **Scalable**: Handles thousands of commands efficiently
- **Low resource usage**: Text-based with minimal memory footprint

## Security Considerations

- Input validation prevents command injection (validate_command_name function)
- SHA256 checksums verify file integrity during updates
- Requires sudo only for system-wide installation operations
- No network access during normal operation (only for updates)
- Clean error handling with proper exit codes