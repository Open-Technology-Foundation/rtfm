# rtfm - Read The Fucking Manuals

A smart command-line utility that searches for documentation about commands across multiple help systems and concatenates the results.

## Features

- Searches for command help in the following order:
  - Bash builtin help
  - Man pages
  - Info pages
  - TLDR pages (if installed)
- Combines results from all available documentation sources
- Uses markdown formatting with md2ansi support (if installed)
- Clean pagination with less
- Easy list rebuilding for keeping documentation sources up-to-date

## Installation

```bash
# Clone the repository
git clone https://github.com/Open-Technology-Foundation/rtfm.git

# Install to system directory (requires sudo)
sudo mkdir -p /usr/local/share/rtfm
sudo cp -r rtfm/* /usr/local/share/rtfm/

# Create symlink to executable
sudo ln -sf /usr/local/share/rtfm/rtfm /usr/local/bin/rtfm

# Optional: Rebuild help lists on first run
rtfm --rebuild-lists

# Optional: Install tldr for additional documentation
# Debian/Ubuntu
sudo apt install tldr

# Fedora
sudo dnf install tldr

# Arch Linux
sudo pacman -S tldr

# macOS
brew install tldr

# Using npm
npm install -g tldr
```

## Usage

```bash
rtfm [OPTIONS] command

Options:
  -r,--rebuild-lists  Rebuild command lists for each help command
  -h,--help           Display this help

Examples:
  rtfm rsync      # Show documentation for rsync
  rtfm declare    # Show documentation for bash's declare builtin
  rtfm ls         # Show documentation for ls
  rtfm git        # Show documentation for git
```

rtfm searches for documentation in these list files:
- builtin.list - Bash builtin commands
- man.list - Commands with man pages
- info.list - Commands with info pages
- tldr.list - Commands with TLDR pages

Run `rtfm --rebuild-lists` to generate or update these files.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Authors

Gary Dean with Claude Code 0.2.29