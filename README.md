# rtfm - Read The Fucking Manuals

A smart command-line utility that searches for documentation about commands across multiple help systems.

## Features

- Searches for command help in the following order:
  - Bash builtin help
  - Man pages
  - Info pages
  - TLDR pages (if installed)
- Combines results from multiple sources
- Supports filtering by documentation source (help, man, info)
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
```

## Usage

```bash
rtfm [OPTIONS] command...

Options:
  -m, --man       Search 'man' only
  -H, --Help      Search 'help' only
  -i, --info      Search 'info' only
  -V, --version   Print version and exit
  -h, --help      Display this help

Other options are passed to 'man' (eg, -k, -K)

Examples:
  rtfm rsync      # Show documentation for rsync
  rtfm declare    # Show documentation for declare
  rtfm -m ls      # Show only man page for ls
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Authors

Gary Dean with Claude Code 0.2.29
