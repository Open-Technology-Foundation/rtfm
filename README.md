# rtfm - Read The Fucking Manuals

A Linux command-line utility that searches for documentation about commands across multiple help systems and concatenates the results.

The `rtfm` program is designed to address the problem of efficiently accessing and consolidating documentation for Linux commands from multiple help systems.

Users often need to refer to various sources of documentation, such as Bash built-in help, man pages, info pages, and TLDR pages.

`rtfm` searches through all these different documentation sources and combines the results, thus simplifying the process of finding relevant information about commands.

## Features

- Searches for command help in the following order:
  - Bash builtin help
  - Man pages
  - Info pages
  - TLDR pages
- **Combines results** from all available documentation sources
- Uses markdown formatting with `md2ansi` support
- Clean pagination with `less`
- Easy list rebuilding for keeping documentation sources up-to-date
- **SHA256 checksum verification** for secure updates (requires `sha256sum`)

## Installation

The easiest way to install `rtfm` and dependencies is to use the built-in installer:

```bash
# Download the script
wget https://raw.githubusercontent.com/Open-Technology-Foundation/rtfm/main/rtfm
# Make it executable
chmod +x rtfm
# Install rtfm, md2ansi, and tldr from GitHub
sudo ./rtfm --install
```

Or as a one-liner:

```bash
wget https://raw.githubusercontent.com/Open-Technology-Foundation/rtfm/main/rtfm && chmod +x rtfm && sudo ./rtfm --install
```

This will automatically install:
- git (if not already installed)
- rtfm (documentation lookup utility)
- md2ansi (markdown to terminal converter for nicer formatting)
- tldr pages (simplified command documentation and examples)

### Updating

To update rtfm:

```bash
# Update rtfm, md2ansi, and tldr from GitHub
sudo rtfm --update
```

## Usage

```bash
rtfm [OPTIONS] command

Options:
  -r,--rebuild-lists  Rebuild command lists for each help source
  --install,--update  Install or update rtfm, md2ansi, and tldr
                      from GitHub
  -v,--verbose        Verbose output during operations (default)
  -q,--quiet          Suppress verbose output during install and
                      update operations
  -V,--version        Print version ($VERSION)
  -h,--help           Display this help

Examples:
  rtfm rsync
  rtfm declare
  rtfm coreutils
  rtfm find
  rtfm --update
  rtfm -r
```

rtfm searches for documentation in these list files:
- builtin.list - Bash builtin commands
- man.list - Commands with man pages
- info.list - Commands with info pages
- tldr.list - Commands with TLDR pages

Run `rtfm --rebuild-lists` to generate or update these files.

## Security

The `rtfm` update mechanism includes SHA256 checksum verification to ensure the integrity of downloaded files. When updating, the script:

1. Downloads repositories from GitHub
2. Downloads and verifies checksums (if `sha256sum` is available)
3. Only installs verified files
4. Automatically rolls back on verification failure

To manually verify the integrity of the installation, check the `checksums.sha256` file in the repository.

### Maintaining Checksums

The `checksums.sha256` file must be updated whenever tracked files change. There are three ways to ensure this:

1. **Manual Update**: Run `./update-checksums.sh` before committing changes
2. **Git Hook**: The pre-commit hook automatically updates checksums (install with `cp .git/hooks/pre-commit.example .git/hooks/pre-commit`)
3. **GitHub Actions**: The workflow automatically updates checksums on push (requires GitHub Actions enabled)

## Dependencies

- bash - For script execution
- grep - For searching through documentation
- less - For paginated viewing
- man - For man page documentation
- info - For info page documentation
- tldr - For simplified command documentation with examples\*
- md2ansi - For better formatted output\*
- git - For installation and update operations\*
- sha256sum - For checksum verification during updates (optional but recommended)

\* Installed with --install

## License

This project is licensed under the GNU General Public License v3.0 - see [LICENSE](LICENSE) for details.
