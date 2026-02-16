# .dotfiles

Personal dotfiles for macOS and Linux environments with zsh, neovim, tmux, git, SSH, and automation scripts.

## Features

- **Shell**: zsh with Oh My Zsh (sonicradish theme, fzf, git plugins)
- **Editor**: Neovim with LazyVim plugin management
- **Terminal**: Alacritty (macOS + Linux), Terminator (Linux)
- **Multiplexer**: tmux with plugins (resurrect, continuum, pomodoro) + tmuxinator session templates
- **Git**: Custom aliases, hooks (email validation, secret scanning via gitleaks), delta pager
- **SSH**: Secure defaults, connection multiplexing, strong crypto
- **Automation**: 30+ utility scripts for system maintenance, git workflows, and development
- **Multi-platform**: Supports both macOS and Linux with platform-specific configs
- **Claude Code**: Pre-configured settings, hooks, and permissions

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

4. (Optional) Link additional configs:
   ```bash
   # Git (hooks + aliases)
   # Already configured via git/.gitconfig templatedir

   # SSH
   ln -s ~/dotfiles/ssh/config ~/.ssh/config
   mkdir -p ~/.ssh/sockets

   # Tmux
   ln -s ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf

   # Neovim
   ln -s ~/dotfiles/nvim ~/.config/nvim

   # Alacritty
   ln -s ~/dotfiles/alacritty ~/.config/alacritty

   # Claude Code
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
├── bin/                    # 30+ utility scripts
├── shell/                  # Shell configuration
│   ├── zshrc               # Main zsh config (Oh My Zsh, plugins)
│   ├── config              # General shell settings + platform detection
│   ├── alias               # Cross-platform aliases
│   ├── functions            # Shell functions (tre, mkd, nvims)
│   ├── path                # PATH configuration
│   ├── osx/                # macOS-specific aliases, functions, path, config
│   ├── linux/              # Linux-specific aliases, functions, path, config
│   └── local-overrides     # Personal env vars (gitignored)
├── git/                    # Git configuration
│   ├── .gitconfig          # Aliases, colors, delta pager
│   └── templates/hooks/    # pre-commit (email + gitleaks), post-commit
├── ssh/                    # SSH configuration
│   └── config              # Secure defaults, multiplexing, known hosts hashing
├── tmux/                   # Tmux configuration
│   └── .tmux.conf          # Prefix C-a, plugins, key bindings
├── tmuxinator/             # Tmux session templates (7 project layouts)
├── nvim/                   # Neovim configuration (LazyVim)
├── alacritty/              # Alacritty terminal (Linux + macOS configs)
├── terminator/             # Terminator terminal (Linux)
├── vscode/                 # VS Code settings
├── cursor/                 # Cursor IDE settings
├── claude/                 # Claude Code settings and hooks
├── xdg/                    # XDG desktop entries and autostart (Linux)
├── docs/                   # Additional documentation
└── screenshots/            # Terminal screenshots
```

## Utility Scripts

### Email and Notifications

| Script | Description |
|--------|-------------|
| [send-ses](bin/send-ses) | Send emails via AWS SES |
| [low-space-monitor.sh](bin/low-space-monitor.sh) | Monitor disk space, send alerts when threshold exceeded |

### Git Workflows

| Script | Description |
|--------|-------------|
| [git-up](bin/git-up) | Pull with short log of changes |
| [git-delete-local-merged](bin/git-delete-local-merged) | Clean up merged local branches |
| [git-copy-branch-name](bin/git-copy-branch-name) | Copy current branch name to clipboard |
| [git-undo](bin/git-undo) | Undo last commit |
| [git-nuke](bin/git-nuke) | Force delete a branch (local + remote) |
| [git-promote](bin/git-promote) | Promote branch to main |
| [git-track](bin/git-track) | Track a remote branch |
| [git-count](bin/git-count) | Commit statistics |
| [git-rank-contributors](bin/git-rank-contributors) | Top contributors by commit count |
| [git-wtf](bin/git-wtf) | Repository status analysis |
| [git-unpushed](bin/git-unpushed) | Show unpushed commits |
| [sync-github.sh](bin/sync-github.sh) | Auto-sync directories to GitHub with per-repo config |

### System Maintenance

| Script | Description |
|--------|-------------|
| [clean-cookies.py](bin/clean-cookies.py) | Clean browser cookies with domain whitelist (Chrome, Brave, Firefox) |
| [clean-downloads.sh](bin/clean-downloads.sh) | Remove files older than 30 days from Downloads |
| [clean-caches.sh](bin/clean-caches.sh) | System cache cleanup |
| [backup-ubuntu-home](bin/backup-ubuntu-home) | Backup home directory with exclusions |
| [hosts-whitelist](bin/hosts-whitelist) | Manage /etc/hosts with domain blacklist |
| [organize-workspaces](bin/organize-workspaces) | Arrange windows across monitors |
| [change-hostname](bin/change-hostname) | System hostname management |
| [prune_node_modules](bin/prune_node_modules) | Clean up node_modules across projects |

### Development Tools

| Script | Description |
|--------|-------------|
| [c](bin/c) | Quick project launcher (VS Code) |
| [createnewproject](bin/createnewproject) | Scaffold new project structure |
| [list-space-color](bin/list-space-color) | Directory sizes with color-coded output |
| [video-clip](bin/video-clip) | Extract video segments with ffmpeg |
| [todo](bin/todo) | Quick todo management |
| [search](bin/search) | Find files |

## Git Hooks

The git template directory (`git/templates/`) provides hooks for all new repositories:

- **pre-commit**: Validates `user.email` is configured and scans staged changes for secrets using [gitleaks](https://github.com/gitleaks/gitleaks)
- **post-commit**: Optional audio notification (disabled by default)

Install gitleaks to enable secret scanning:
```bash
# macOS
brew install gitleaks

# Linux
sudo apt install gitleaks
# or grab a binary: https://github.com/gitleaks/gitleaks/releases
```

## Screenshots

![Screenshot of my nvim prompt](https://raw.githubusercontent.com/iloire/dotfiles/main/screenshots/nvim-iterm.png)

## Credits

Inspiration from:
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [holman/dotfiles](https://github.com/holman/dotfiles)
- [ThePrimeagen/dotfiles](https://github.com/ThePrimeagen/dotfiles)
