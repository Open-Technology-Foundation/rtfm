# rtfm - Read The Fucking Manuals

A smart command-line utility that searches for documentation about commands across multiple help systems.

## Features

- Searches for command help in the following order:
  - Bash builtin help
  - Man pages
  - Info pages
  - Command --help output
  - TLDR pages (if installed)
- View all available documentation sources with --all flag
- Combines results from multiple sources
- Supports filtering by documentation source (help, man, info, cmd-help)
- Uses secure temporary files
- Clean error handling

## Installation

```bash
# Clone the repository
git clone https://github.com/Open-Technology-Foundation/rtfm.git

# Move to your bin directory
cp rtfm/rtfm ~/bin/

# Make executable
chmod +x ~/bin/rtfm

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
rtfm [OPTIONS] command...

Options:
  -m, --man       Search 'man' only
  -H, --Help      Search 'help' only
  -i, --info      Search 'info' only
  -c, --cmd-help  Search command --help output only
  -a, --all       Show all available documentation (not just first match)
  -V, --version   Print version and exit
  -h, --help      Display this help

Other options are passed to 'man' (eg, -k, -K)

Examples:
  rtfm rsync      # Show documentation for rsync
  rtfm declare    # Show documentation for bash's declare builtin
  rtfm -m ls      # Show only man page for ls
  rtfm -a git     # Show all available documentation for git
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Authors

Gary Dean with Claude Code 0.2.29
