# rtfm - Read The Fucking Manuals

A unified Linux documentation lookup tool that consolidates help information from multiple sources into a single, easy-to-use interface.

## Overview

`rtfm` solves the common problem of fragmented documentation by searching across all available help systems and presenting the results in one place. Instead of remembering whether to use `man`, `info`, `help`, or `tldr`, just use `rtfm`.

## Features

- **Multi-source documentation search** in order:
  1. Bash builtin help
  2. Man pages (from all directories in `manpath`)
  3. Info pages
  4. TLDR pages (simplified examples)
  5. Command --help (for scripts without formal documentation)
- **Smart fallback**: Automatically detects and runs `--help` for text-based scripts
- **Fast lookups**: Pre-built indices enable O(1) performance
- **Update detection**: Warns when new man pages are installed
- **Secure updates**: SHA256 checksum verification
- **Enhanced formatting**: Optional markdown rendering with `md2ansi`
- **Clean pagination**: Integrated with `less` for easy navigation

## Installation

### Quick Install

```bash
# One-liner installation
wget https://raw.githubusercontent.com/Open-Technology-Foundation/rtfm/main/rtfm && chmod +x rtfm && sudo ./rtfm --install
```

### Step-by-Step Install

```bash
# Download the script
wget https://raw.githubusercontent.com/Open-Technology-Foundation/rtfm/main/rtfm

# Make it executable
chmod +x rtfm

# Install rtfm and dependencies
sudo ./rtfm --install
```

This installs:
- `rtfm` to `/usr/local/share/rtfm/` with symlink in `/usr/local/bin/`
- `md2ansi` for enhanced markdown formatting
- `tldr` pages for simplified command examples
- Pre-generated documentation indices for your system

## Usage

### Basic Lookup

```bash
rtfm <command>
```

### Examples

```bash
# Look up rsync documentation (finds man page + tldr examples)
rtfm rsync

# Get help for bash's declare builtin
rtfm declare

# View comprehensive GNU coreutils documentation
rtfm coreutils

# Find all documentation for the find command
rtfm find

# Get help for a custom script (fallback to --help)
rtfm my-script
```

### Administrative Commands

```bash
# Update rtfm and all dependencies
sudo rtfm --update

# Rebuild documentation indices after installing new packages
sudo rtfm --rebuild-lists

# View version information
rtfm --version

# Display help
rtfm --help
```

### Options

- `-r, --rebuild-lists`: Rebuild command lists from documentation sources
- `--install, --update`: Install or update rtfm and dependencies
- `-v, --verbose`: Verbose output (default)
- `-q, --quiet`: Suppress verbose messages
- `-V, --version`: Display version information
- `-h, --help`: Show help message

## How It Works

### Documentation Sources

rtfm searches these locations in order:

1. **Bash Builtins** (`/usr/local/share/rtfm/builtin.list`)
   - Generated from `compgen -b`
   - Covers commands like `cd`, `alias`, `declare`, etc.

2. **Man Pages** (`/usr/local/share/rtfm/man.list`)
   - Searches all directories from `manpath`
   - Includes both compressed (.gz) and uncompressed pages
   - Automatically detects new installations

3. **Info Pages** (`/usr/local/share/rtfm/info.list`)
   - GNU project documentation
   - Often more detailed than man pages

4. **TLDR Pages** (`/usr/local/share/rtfm/tldr.list`)
   - Community-maintained simplified examples
   - Great for quick command usage references

5. **Command --help** (fallback)
   - For executable scripts without formal documentation
   - Detects if script contains `--help` option
   - Only runs if script is a text file (not binary)

### Update Detection

rtfm monitors man page directories and warns when new pages are installed:

```
rtfm: Warning: New man pages detected. Run 'sudo rtfm --rebuild-lists' to update the index.
```

This ensures your documentation index stays current without manual intervention.

### Security Features

- **Input validation**: Prevents command injection with strict character whitelisting
- **SHA256 checksums**: Verifies integrity of downloaded files
- **Automatic rollback**: Restores previous version if update fails
- **Privilege checks**: Uses `can_sudo` to verify permissions before system changes

## File Locations

- **Executable**: `/usr/local/bin/rtfm` (symlink to `/usr/local/share/rtfm/rtfm`)
- **Documentation indices**: `/usr/local/share/rtfm/*.list`
- **TLDR pages**: `/usr/local/share/tldr/`
- **md2ansi**: `/usr/local/share/md2ansi/`

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
- **file**: For detecting script types in --help fallback

## Troubleshooting

### rtfm not finding a command
```bash
# Rebuild the documentation indices
sudo rtfm --rebuild-lists
```

### Installation fails
```bash
# Check if you have sudo access
groups | grep -E 'sudo|admin|wheel'

# Install git manually if needed
sudo apt-get install git
```

### Checksum verification fails
```bash
# Install sha256sum for security
sudo apt-get install coreutils

# Or skip verification (not recommended)
# The installer will warn but continue
```

## Contributing

1. Fork the repository
2. Make your changes
3. Run `./update-checksums.sh` before committing
4. Submit a pull request

## License

GNU General Public License v3.0 - see [LICENSE](LICENSE) for details.

## Links

- [GitHub Repository](https://github.com/Open-Technology-Foundation/rtfm)
- [md2ansi](https://github.com/Open-Technology-Foundation/md2ansi)
- [tldr pages](https://github.com/Open-Technology-Foundation/tldr)