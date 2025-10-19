# .dotfiles

Personal dotfiles for macOS and Linux environments with zsh, nvim, git configurations, and automation scripts.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Environment Variables](#environment-variables)
- [Directory Structure](#directory-structure)
- [Utility Scripts](#utility-scripts)
- [Claude Code Integration](#claude-code-integration)
- [Screenshots](#screenshots)
- [Credits](#credits)

## Features

- **Shell**: zsh with Oh My Zsh configuration
- **Editor**: Neovim setup with custom configurations
- **Git**: Custom templates, hooks, and aliases
- **Automation**: Collection of utility scripts for system maintenance
- **Multi-platform**: Supports both macOS and Linux
- **Claude Code**: Pre-configured settings and hooks

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/iloire/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Set up environment variables:
   ```bash
   cp shell/local-overrides.template shell/local-overrides
   # Edit shell/local-overrides with your personal values
   ```

3. Source the shell configuration:
   ```bash
   # Add to your ~/.zshrc:
   source ~/dotfiles/shell/zshrc
   ```

4. (Optional) Set up Claude Code settings:
   ```bash
   # Link Claude Code settings
   ln -s ~/dotfiles/claude/settings.json ~/.claude/settings.json
   ```

## Environment Variables

See [ENV.md](ENV.md) for complete documentation of all environment variables.

**Required:**
- `ADMIN_EMAIL` - Email address for notifications

**Configuration Template:**
```bash
cp shell/local-overrides.template shell/local-overrides
# Edit with your values
```

## Directory Structure

```
dotfiles/
├── bin/                    # Utility scripts
│   ├── send-ses.sh        # Send emails via AWS SES
│   ├── sync-github.sh     # Sync repositories to GitHub
│   ├── clean-cookies.py   # Clean browser cookies with whitelist
│   ├── low-space-monitor.sh # Monitor disk space and send alerts
│   └── backup-ubuntu-home.sh # Backup home directory
├── shell/                  # Shell configuration
│   ├── zshrc              # Main zsh configuration
│   ├── config             # General shell settings
│   ├── functions          # Custom shell functions
│   ├── alias              # Shell aliases
│   ├── path               # PATH configuration
│   ├── osx/               # macOS-specific settings
│   ├── linux/             # Linux-specific settings
│   └── local-overrides    # Personal env vars (gitignored)
├── git/                    # Git configuration
│   ├── .gitconfig         # Global git settings
│   └── templates/hooks/   # Git hooks
├── claude/                 # Claude Code configuration
│   └── settings.json      # Claude Code settings
├── nvim/                   # Neovim configuration
└── xdg/                    # XDG desktop entries (Linux)
```

## Utility Scripts

### Email and Notifications

**[bin/send-ses.sh](bin/send-ses.sh)**
- Send emails via AWS SES
- Usage: `send-ses.sh <subject> <message>`
- Requires: `ADMIN_EMAIL`, AWS credentials in `~/.aws/credentials`

**[bin/low-space-monitor.sh](bin/low-space-monitor.sh)**
- Monitor disk space and send alerts when threshold exceeded
- Usage: `low-space-monitor.sh [--verbose] [--quiet]`
- Threshold: 90% disk usage
- Sends email via SES when space is low

### GitHub and Version Control

**[bin/sync-github.sh](bin/sync-github.sh)**
- Sync multiple repositories to GitHub
- Usage: `sync-github.sh [--verbose] [--quiet]`
- Config: `~/github_sync.conf`
- Supports per-directory `.sync_config` files

**[bin/git-up](bin/git-up)**
- Update git repository (fetch, rebase, cleanup)

### System Maintenance

**[bin/clean-cookies.py](bin/clean-cookies.py)**
- Clean browser cookies while preserving whitelisted domains
- Usage: `clean-cookies.py [--verbose] [--quiet]`
- Config: `~/myconfig/cookies-whitelist.txt`
- Supports Chrome, Brave, Firefox
- Stop flag: `~/stop_cookie_cleaning.txt`

**[bin/clean-downloads.sh](bin/clean-downloads.sh)**
- Clean old files from Downloads folder
- Deletes files older than 30 days

**[bin/hosts-whitelist.sh](bin/hosts-whitelist.sh)**
- Manage /etc/hosts with domain blacklist
- Config: `~/myconfig/hosts-google-blacklist.txt`

**[bin/backup-ubuntu-home.sh](bin/backup-ubuntu-home.sh)**
- Backup Ubuntu home directory with exclusions
- Usage: `backup-ubuntu-home.sh --backup-dir /path/to/backup [--verbose]`

### Development Tools

**[bin/list-space-color.sh](bin/list-space-color.sh)**
- Display directory sizes with color-coded output

**[bin/c.sh](bin/c.sh)**
- Quick project directory navigation

**[bin/createnewproject](bin/createnewproject)**
- Scaffold new project with template structure

## Claude Code Integration

Pre-configured Claude Code settings with:
- Tool call hooks for logging
- Environment variables (`CLAUDE_CODE_VERBOSE`, `CLAUDE_CODE_ENABLE_TELEMETRY`)
- Permissions for common operations
- Custom working directories

**Configuration:** [claude/settings.json](claude/settings.json)

## Screenshots

![Screenshot of my nvim prompt](https://raw.githubusercontent.com/iloire/dotfiles/main/screenshots/nvim-iterm.png)

## Credits

Inspiration from:
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [holman/dotfiles](https://github.com/holman/dotfiles)
- [ThePrimeagen/dotfiles](https://github.com/ThePrimeagen/dotfiles)
