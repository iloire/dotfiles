# Environment Variables Documentation

This document describes all environment variables used in the dotfiles repository.

## Setup Instructions

1. Copy the template file:
   ```bash
   cp shell/local-overrides.template shell/local-overrides
   ```

2. Edit `shell/local-overrides` with your personal values

3. The file is automatically gitignored and will not be pushed to the repository

## Required Variables

### ADMIN_EMAIL
- **Purpose**: Email address for system notifications and alerts
- **Used by**:
  - [bin/send-ses.sh](bin/send-ses.sh:12) - Sends email via AWS SES
  - [bin/low-space-monitor.sh](bin/low-space-monitor.sh:35) - Disk space alerts
- **Example**: `export ADMIN_EMAIL="your-email@example.com"`
- **Required**: Yes (scripts will exit if not set)

## Optional Variables

### AWS Configuration

#### AWS Credentials
- **Purpose**: AWS SES credentials for sending emails
- **Configuration**: Must be set in `~/.aws/credentials` under `[email]` profile
- **Used by**: [bin/send-ses.sh](bin/send-ses.sh)
- **Required**: Only if using `send-ses.sh`
- **Example**:
  ```ini
  # In ~/.aws/credentials
  [email]
  aws_access_key_id = YOUR_ACCESS_KEY
  aws_secret_access_key = YOUR_SECRET_KEY
  ```

### Shell Configuration

#### SHELL_DIR
- **Purpose**: Points to shell configuration directory
- **Used by**: [shell/zshrc](shell/zshrc:25), [shell/config](shell/config)
- **Default**: `~/dotfiles/shell`
- **Auto-set**: Yes (by zshrc)

#### ZSH_THEME
- **Purpose**: Oh My Zsh theme name
- **Used by**: [shell/zshrc](shell/zshrc:8)
- **Default**: `sonicradish`
- **Example**: `export ZSH_THEME="agnoster"`

#### UPDATE_ZSH_DAYS
- **Purpose**: Frequency of Oh My Zsh auto-update checks (in days)
- **Used by**: [shell/zshrc](shell/zshrc:14)
- **Default**: `30`

#### FZF_BASE
- **Purpose**: Path to fzf binary for fuzzy finding
- **Used by**: [shell/zshrc](shell/zshrc:32)
- **Default**: `/usr/local/bin/fzf`

### Editor and Display

#### EDITOR
- **Purpose**: Default text editor for command-line operations
- **Used by**: [shell/config](shell/config:17)
- **Default**: `nvim`
- **Example**: `export EDITOR="vim"` or `export EDITOR="code"`

#### CLICOLOR
- **Purpose**: Enable colors in CLI output
- **Used by**: [shell/config](shell/config:4)
- **Default**: `1`

#### LS_COLORS (Linux)
- **Purpose**: Color scheme for GNU ls command
- **Used by**: [shell/config](shell/config:8)
- **Auto-set**: Yes (by config)

#### LSCOLORS (macOS)
- **Purpose**: Color scheme for macOS ls command
- **Used by**: [shell/config](shell/config:11)
- **Default**: `BxBxhxDxfxhxhxhxhxcxcx`

### Development Tools

#### GOPATH
- **Purpose**: Go workspace directory
- **Used by**: [shell/config](shell/config:15)
- **Default**: `$HOME/code/gocode`
- **Required**: Only if using Go

#### JAVA_HOME (macOS)
- **Purpose**: Java installation directory
- **Used by**: [shell/osx/config](shell/osx/config:10)
- **Default**: `$HOME/code/jdk-22.0.2.jdk/Contents/Home/`
- **Required**: Only if using Java

#### NVM_DIR
- **Purpose**: Node Version Manager directory
- **Used by**: [shell/osx/config](shell/osx/config:3), [shell/linux/config](shell/linux/config:2)
- **Default**: `$HOME/.nvm`
- **Required**: Only if using nvm

#### HOMEBREW_NO_ANALYTICS
- **Purpose**: Disable Homebrew analytics collection
- **Used by**: [shell/config](shell/config:16)
- **Default**: `1`

#### NVIM_APPNAME
- **Purpose**: Neovim configuration selector
- **Used by**: [shell/functions](shell/functions:65) (nvims function)
- **Auto-set**: Yes (by nvims function)

### Claude Code

#### CLAUDE_CODE_ENABLE_TELEMETRY
- **Purpose**: Control telemetry collection
- **Used by**: [claude/settings.json](claude/settings.json:20)
- **Default**: `0` (disabled)
- **Example**: `export CLAUDE_CODE_ENABLE_TELEMETRY="0"`

#### CLAUDE_CODE_VERBOSE
- **Purpose**: Enable verbose logging
- **Used by**: [claude/settings.json](claude/settings.json:21)
- **Default**: `1` (enabled)
- **Example**: `export CLAUDE_CODE_VERBOSE="1"`

### Backup Scripts

#### BACKUP_DIR_ENV
- **Purpose**: Destination directory for backup files
- **Used by**: [bin/backup-ubuntu-home.sh](bin/backup-ubuntu-home.sh)
- **Alternative**: Can use `--backup-dir` command-line argument instead
- **Example**: `export BACKUP_DIR_ENV="/mnt/backups"`

## Configuration Files Expected

Beyond environment variables, several scripts expect configuration files:

| File | Purpose | Used By | Required |
|------|---------|---------|----------|
| `~/github_sync.conf` | GitHub sync configuration | [bin/sync-github.sh](bin/sync-github.sh) | Yes |
| `~/myconfig/cookies-whitelist.txt` | Cookie whitelist | [bin/clean-cookies.py](bin/clean-cookies.py) | Yes |
| `~/myconfig/hosts-google-blacklist.txt` | Hosts blacklist | [bin/hosts-whitelist.sh](bin/hosts-whitelist.sh) | Yes |
| `~/.aws/credentials` | AWS credentials | [bin/send-ses.sh](bin/send-ses.sh) | For SES |
| `~/stop_cookie_cleaning.txt` | Disable cookie cleaning | [bin/clean-cookies.py](bin/clean-cookies.py) | No |
| `<dir>/.sync_config` | Per-directory sync config | [bin/sync-github.sh](bin/sync-github.sh) | No |

## PATH Modifications

The following directories are automatically added to PATH (if they exist):

- `$HOME/dotfiles/bin` - Custom scripts
- `$HOME/bin` - User binaries
- `/usr/local/go/bin` - Go binaries
- `$GOPATH/bin` - Go workspace binaries
- `$HOME/.rvm/bin` - Ruby Version Manager
- `$HOME/.yarn/bin` - Yarn global binaries
- `$HOME/.config/yarn/global/node_modules/.bin` - Yarn global modules
- `$HOME/miniconda3/bin` - Conda environment
- `$HOME/.local/bin` (macOS) - User local binaries
- `/opt/homebrew/bin` (macOS) - Homebrew binaries
- `/Applications/Postgres.app/Contents/Versions/latest/bin` (macOS) - PostgreSQL
- `/usr/local/opt/python/libexec/bin` (macOS) - Python

## Platform-Specific Variables

### macOS Only
- `JAVA_HOME`
- `LSCOLORS`
- `GHC_DOT_APP` (Haskell)

### Linux Only
- `LS_COLORS`
- `XDG_DATA_DIRS`
