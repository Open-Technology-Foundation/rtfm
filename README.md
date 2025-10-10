# rtfm - Read The Fucking Manuals

A unified Linux documentation lookup tool that consolidates help information from multiple sources into a single, easy-to-use interface.

## Overview

`rtfm` solves the common problem of fragmented documentation by searching across all available help systems and presenting the results in one place. Instead of remembering whether to use `man`, `info`, `help`, or `tldr`, just use `rtfm`.

## Features

- **Multi-source documentation search** in priority order:
  1. Bash builtin help
  2. Man pages (from all directories in `manpath`)
  3. Info pages
  4. TLDR pages (simplified examples)
  5. Command --help (automatic fallback for scripts)
- **Smart color detection**: Automatically disables ANSI colors when redirecting to files or pipes
- **Color control**: Respects standard environment variables (`NO_COLOR`, `FORCE_COLOR`, `CLICOLOR_FORCE`)
- **Fast O(1) lookups**: Pre-built indices enable instant searches
- **Update detection**: Warns when new man pages are installed
- **Secure updates**: SHA256 checksum verification with automatic rollback
- **Enhanced formatting**: Optional markdown rendering with `md2ansi`
- **Smart fallback**: Automatically detects and runs `--help` for text-based scripts
- **Clean pagination**: Integrated with `less` for easy navigation
- **Security hardened**: Input validation, PATH lockdown, privilege checks

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

# Display help
rtfm --help

# Show version
rtfm --version
```

### Options

| Option | Description |
|--------|-------------|
| `-r, --rebuild-lists` | Rebuild command lists from documentation sources (requires sudo) |
| `--install, --update` | Install or update rtfm and dependencies from GitHub |
| `-v, --verbose` | Verbose output during operations (default) |
| `-q, --quiet` | Suppress verbose messages |
| `-V, --version` | Display version information |
| `-h, --help` | Show help message |

## Color Output

rtfm automatically detects terminal capabilities and adjusts ANSI color output accordingly:

### Automatic Behavior

- **Terminal (TTY)**: Colors enabled by default
  ```bash
  rtfm ls  # Colorful output in terminal
  ```

- **Redirected to file**: Colors automatically disabled
  ```bash
  rtfm ls >/tmp/ls.txt  # Clean text, no ANSI codes
  ```

- **Piped to commands**: Colors automatically disabled
  ```bash
  rtfm ls | grep -i directory  # Clean text for processing
  ```

### Environment Variables

Control color output explicitly using standard environment variables:

| Variable | Effect | Example |
|----------|--------|---------|
| `NO_COLOR` | Disable all colors (any value) | `NO_COLOR=1 rtfm ls` |
| `FORCE_COLOR` | Force colors even when redirected | `FORCE_COLOR=1 rtfm ls >file.txt` |
| `CLICOLOR_FORCE` | Force colors (alternative to FORCE_COLOR) | `CLICOLOR_FORCE=1 rtfm ls` |

### Examples

```bash
# Disable colors explicitly
NO_COLOR=1 rtfm ls

# Force colors when redirecting (useful for HTML conversion)
FORCE_COLOR=1 rtfm ls >/tmp/ls-colored.txt

# Clean text for scripting
rtfm ls 2>/dev/null | awk '/SYNOPSIS/ {print}'
```

### How It Works

Color detection happens at multiple levels:

1. **Main headers** (BUILTIN, MAN, INFO, TLDR): Processed by `md2ansi`
   - Detects stdout TTY status automatically
   - When not a TTY, uses `TERM=dumb` to disable colors

2. **Man pages**: Uses `GROFF_NO_SGR=1` when colors disabled
   - Prevents SGR (Select Graphic Rendition) escape sequences

3. **Error messages** (stderr): Independent TTY detection
   - Diagnostic output can be colored even when stdout is redirected
   - Useful for scripts: `rtfm ls >/tmp/out.txt` shows colored warnings

## How It Works

### Documentation Sources

rtfm searches these locations in priority order:

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

5. **Command --help** (automatic fallback)
   - For executable scripts without formal documentation
   - Detects if script contains `--help` option
   - Only runs if script is a text file (not binary)

### Update Detection

rtfm monitors man page directories and warns when new pages are installed:

```
rtfm: ⚡ New man pages detected. Run 'sudo rtfm --rebuild-lists' to update the index.
```

This ensures your documentation index stays current without manual intervention.

### Security Features

- **Input validation**: Whitelists safe characters, blocks shell metacharacters and path traversal
- **PATH lockdown**: Locked to `/usr/local/bin:/usr/bin:/bin` to prevent command injection
- **SHA256 checksums**: Verifies integrity of downloaded files during updates
- **Automatic rollback**: Restores previous version if update fails
- **Privilege checks**: Uses `can_sudo()` to verify permissions before system changes

## Architecture

### Fast Lookups with Pre-built Indices

Instead of scanning the filesystem every time, rtfm uses pre-built indices (`.list` files) for O(1) lookups:

- `builtin.list` - Bash builtins (from `compgen -b`)
- `man.list` - All man pages from manpath directories
- `info.list` - GNU info pages
- `tldr.list` - TLDR simplified examples

These indices are created during installation and can be rebuilt with `sudo rtfm --rebuild-lists`.

### Install/Update System

The `--install` and `--update` flags:
1. Clone rtfm, md2ansi, and tldr from GitHub to temporary directories
2. Verify SHA256 checksums (if sha256sum available)
3. Back up existing installations to `.bak`
4. Atomically move verified repositories to final locations
5. Roll back to `.bak` on failure
6. Rebuild all documentation indices

### Output Pipeline

Documentation is concatenated with page breaks and piped through:
- `md2ansi` for markdown formatting (TLDR content and headers)
  - Automatically detects TTY and adjusts color output
  - Respects `NO_COLOR` and `FORCE_COLOR` environment variables
- `less -RFSX` for pagination with color support

## File Locations

- **Executable**: `/usr/local/bin/rtfm` (symlink to `/usr/local/share/rtfm/rtfm`)
- **Documentation indices**: `/usr/local/share/rtfm/*.list`
- **TLDR pages**: `/usr/local/share/tldr/`
- **md2ansi**: `/usr/local/share/md2ansi/`

## Dependencies

### Required
- **bash** (5.2+): Script execution environment
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

### Colors appear in redirected files

```bash
# This should not happen with latest version
# If it does, use NO_COLOR to disable:
NO_COLOR=1 rtfm ls >/tmp/file.txt

# Or check md2ansi version:
md2ansi --version  # Should be 0.9.6-bash or later
```

## Development

### Code Standards

This project achieves **100% compliance** with strict Bash coding standards:

- **[BASH-CODING-STANDARD.md](BASH-CODING-STANDARD.md)** - Full compliance with comprehensive Bash 5.2+ standard
  - Bottom-up function organization (messaging → validation → business logic → main)
  - Proper variable expansion (`"$var"` without unnecessary braces)
  - Single quotes for static strings, double quotes only when needed
  - Case statements following one-word literal exception (`case $1 in`)
- **ShellCheck validation** - Zero warnings (compulsory)
- **Security-first design** - PATH lockdown, input validation, checksum verification
- **Proper error handling** - `set -euo pipefail` with comprehensive die() function
- **2-space indentation** - Consistent formatting throughout

### Testing

```bash
# Lint the script
shellcheck rtfm

# Test basic functionality
rtfm --help
rtfm --version
rtfm echo

# Test color detection
rtfm ls                      # Should have colors in TTY
rtfm ls >/tmp/test.txt       # Should be clean text
NO_COLOR=1 rtfm ls           # Should have no colors
FORCE_COLOR=1 rtfm ls >/tmp/test.txt  # Should have colors

# Test rebuilding indices (requires sudo)
sudo rtfm --rebuild-lists
```

### Contributing

1. Fork the repository
2. Make your changes following BASH-CODING-STANDARD.md
3. Run `./update-checksums.sh` before committing
4. Ensure `shellcheck rtfm` passes with no warnings
5. Submit a pull request

## Version History

### v1.2.0 (Current) - Smart Color Detection & Code Quality

**Color Output Features:**
- ✅ **Automatic TTY detection** - ANSI colors automatically disabled when output is redirected to files or pipes
- ✅ **Environment variable support** - Respects `NO_COLOR`, `FORCE_COLOR`, and `CLICOLOR_FORCE` standard variables
- ✅ **md2ansi integration** - Uses `TERM=dumb` to disable colors in markdown formatting when appropriate
- ✅ **Man page color control** - Sets `GROFF_NO_SGR=1` to prevent SGR escape sequences when colors disabled
- ✅ **Independent stderr colors** - Error/warning messages check TTY separately for better UX

**Code Quality Improvements:**
- ✅ **100% BASH-CODING-STANDARD.md compliance** - Systematic code review and refactoring
- ✅ **Bottom-up function organization** - Proper dependency order (messaging → validation → business logic → main)
- ✅ **Variable expansion cleanup** - Removed ~55 unnecessary braces
- ✅ **String quoting standardization** - Static strings use single quotes
- ✅ **PATH security lockdown** - Locked to `/usr/local/bin:/usr/bin:/bin`
- ✅ **ShellCheck compliance** - Zero warnings with proper disable directives

**Documentation & Usability:**
- Completely rewrote `usage()` function with 7 comprehensive sections
- Completely rewrote README.md with color detection documentation
- Added comprehensive inline documentation

**Result:** Clean text output when redirected, colored output in terminals, with full user control via environment variables

### v1.1.0
- Added checksum verification for secure updates
- Implemented automatic rollback on failed updates
- Enhanced security with input validation
- Added smart --help fallback for scripts

### v1.0.0
- Initial release
- Multi-source documentation search
- Pre-built indices for fast lookups
- Integrated pagination

## License

GNU General Public License v3.0 - see [LICENSE](LICENSE) for details.

## Links

- [GitHub Repository](https://github.com/Open-Technology-Foundation/rtfm)
- [md2ansi](https://github.com/Open-Technology-Foundation/md2ansi)
- [tldr](https://github.com/Open-Technology-Foundation/tldr)
- [NO_COLOR Standard](https://no-color.org/)

## Related Projects

- **man**: Traditional Unix manual pages
- **info**: GNU documentation system
- **tldr**: Simplified community-driven man pages
- **cheat**: Interactive cheat sheets
- **bro pages**: Crowd-sourced examples

---

**rtfm** - Because reading the manual shouldn't require a manual.
