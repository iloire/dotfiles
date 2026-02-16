# Improvement Candidates

Analysis of gaps and opportunities across both projects:
- **dotfiles** (`~/dotfiles`) — shell config, editor config, utility scripts
- **ansible-recipes** (`~/code/ansible-recipes`) — machine provisioning, package management, system settings

---

## 1. Modern CLI Tools (ansible-recipes + dotfiles)

### Problem
Classic Unix tools (ls, cat, find, du, top, man, diff) have modern replacements that are faster, prettier, and more useful — but they aren't installed or aliased.

### What to install (new ansible role: `modern_cli_tools`)
| Classic | Modern      | Why                                        |
|---------|-------------|--------------------------------------------|
| `ls`    | **eza**     | Git-aware, icons, tree mode built-in       |
| `cat`   | **bat**     | Syntax highlighting, git integration       |
| `find`  | **fd**      | Faster, respects .gitignore, saner syntax  |
| `du`    | **dust**    | Visual disk usage                          |
| `top`   | **btop**    | Beautiful resource monitor                 |
| `man`   | **tldr**    | Quick command examples (tealdeer, Rust)    |
| `diff`  | **delta**   | Better git diffs, syntax highlighting      |

`ripgrep` is already installed via apt.

### Where each change lives
- **ansible-recipes**: New role `modern_cli_tools` that downloads binaries from GitHub releases to `~/.local/bin`. Add to `desktop-ubuntu.yml`, `server-ubuntu.yml`, and macOS playbooks (Homebrew already has most of these).
- **dotfiles**: Conditional aliases in `shell/alias` (see item 2 below).
- **dotfiles**: Switch git pager from `diff-so-fancy` to `delta` in `git/.gitconfig`.

### macOS note
Most of these are already available via Homebrew. Add to `group_vars/osx.yml`:
```yaml
# Add to brew_packages:
- bat
- eza
- fd
- dust
- btop
- tealdeer
- git-delta
```

---

## 2. Discoverability: Don't Forget Your Tools

### Problem
Installing tools is useless if muscle memory keeps reaching for the old ones. Need aliases that make modern tools the default AND a way to discover what's available.

### Solution A: Conditional aliases in `shell/alias`
```bash
# Modern CLI replacements (fall back to classic if not installed)
command -v eza   &>/dev/null && alias ls='eza --icons --group-directories-first' && alias la='eza -la --icons --group-directories-first' && alias lt='eza --tree --icons --level=2'
command -v bat   &>/dev/null && alias cat='bat --paging=never' && alias catp='bat'
command -v fd    &>/dev/null && alias find='fd'
command -v dust  &>/dev/null && alias du='dust'
command -v btop  &>/dev/null && alias top='btop'
command -v delta &>/dev/null && alias diff='delta'
```

This way you just keep typing `ls`, `cat`, `du` etc. and get the modern version automatically. No new commands to memorize.

### Solution B: `tools` command
A shell function that prints a quick reference of all custom tools and aliases:
```bash
tools() {
    echo "=== Modern CLI ==="
    echo "  ls  → eza       cat → bat       find → fd"
    echo "  du  → dust      top → btop      man  → tldr"
    echo "  diff → delta    grep → rg"
    echo ""
    echo "=== Custom Scripts (~/dotfiles/bin) ==="
    echo "  c           Quick project launcher"
    echo "  j/journal   Open daily journal"
    echo "  dun         Disk usage by directory"
    echo "  sync-github Sync repos to GitHub"
    echo "  video-clip  Extract video segment"
    echo "  organize-workspaces  Arrange windows"
    echo ""
    echo "=== Git Shortcuts ==="
    echo "  gs=status  gm=merge  ga=amend  gp=push"
    echo "  gcontrib   lazygit   git-up"
    echo ""
    echo "=== Navigation ==="
    echo "  ..  ...  ....  cdh  cddev  cddrop  dl  d  h"
    echo ""
    echo "=== Tmux ==="
    echo "  mux=tmuxinator  prefix=Ctrl-A"
}
```

### Solution C: Shell startup hint (optional, lightweight)
Show a random tip on shell startup — one line, non-intrusive:
```bash
# Add to zshrc, after sourcing config
if command -v shuf &>/dev/null; then
    echo "\033[2m💡 $(shuf -n1 ~/dotfiles/shell/tips.txt)\033[0m"
fi
```
Where `tips.txt` is a flat file like:
```
Use 'lt' for a tree view with icons (eza --tree)
Use 'tldr <cmd>' instead of man pages for quick examples
Use 'bat' instead of cat for syntax highlighting
Use 'dust' to visualize disk usage
Use 'fd' to find files (respects .gitignore)
Use 'btop' for a beautiful system monitor
Use 'c' to quick-launch projects in VS Code
Use 'tools' to see all custom commands
```

---

## 3. Git Pager: diff-so-fancy → delta

### Problem
`diff-so-fancy` is good but `delta` is strictly better: syntax highlighting, side-by-side view, line numbers, n/N navigation, and it works as both pager and standalone diff tool.

### Change in `git/.gitconfig`
Replace:
```gitconfig
[core]
    pager = diff-so-fancy | less --tabs=4 -RFX
```
With:
```gitconfig
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    side-by-side = true
    line-numbers = true
    syntax-theme = Dracula

[merge]
    conflictstyle = zdiff3
```

### ansible-recipes impact
- Remove `diff-so-fancy` from `group_vars/all.yml` npm_packages (or keep as fallback)
- Add `delta` to the new `modern_cli_tools` role

---

## 4. Shell Startup Performance

### Problem
Current zshrc loads nvm, conda, and oh-my-zsh eagerly. These are the three biggest startup time killers. Measure with `time zsh -i -c exit`.

### Improvement: Lazy-load nvm and conda

In `shell/linux/config` and `shell/osx/config`, replace eager nvm init with lazy loading:
```bash
# Lazy-load nvm — only initializes when you first call nvm, node, npm, npx, or yarn
lazy_load_nvm() {
    unset -f nvm node npm npx yarn
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
}
nvm()  { lazy_load_nvm; nvm "$@"; }
node() { lazy_load_nvm; node "$@"; }
npm()  { lazy_load_nvm; npm "$@"; }
npx()  { lazy_load_nvm; npx "$@"; }
yarn() { lazy_load_nvm; yarn "$@"; }
```

Same pattern for conda. Expected improvement: 200-500ms off startup.

### Longer term: Consider zinit
Replace Oh My Zsh with zinit for turbo-mode (deferred) plugin loading. Significant effort but the fastest zsh framework available.

---

## 5. Zsh Plugins: Autosuggestions + Syntax Highlighting

### Problem
macOS Homebrew already installs `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `zsh-completions` — but dotfiles don't load them. Linux has none of these.

### What they do
- **zsh-autosuggestions**: Ghost-text suggestions from history as you type. Accept with right arrow. Huge productivity boost.
- **zsh-syntax-highlighting**: Colors valid commands green, invalid red, strings yellow — while you type, before hitting enter.
- **zsh-completions**: Richer tab completion for hundreds of tools.

### Changes needed
- **ansible-recipes (Linux)**: New role or add to apt packages — clone the repos to `~/.oh-my-zsh/custom/plugins/`.
- **dotfiles (`shell/zshrc`)**: Add to plugins array:
  ```bash
  plugins=(
      git
      fzf
      last-working-dir
      zsh-autosuggestions
      zsh-syntax-highlighting
  )
  ```

---

## 6. SSH Config

### Problem
No SSH configuration in dotfiles. Every machine gets a bare default SSH setup.

### Add `ssh/config` to dotfiles
```
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountdown 3
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
```

Key benefits:
- **ControlMaster**: Multiplexes connections — second SSH to same host is instant.
- **ServerAliveInterval**: Prevents dropped connections.
- **AddKeysToAgent**: Auto-adds keys on first use.

### ansible-recipes
Add to `dotfiles` role: symlink `~/dotfiles/ssh/config` → `~/.ssh/config` and `mkdir -p ~/.ssh/sockets`.

---

## 7. Git Config Improvements

### Problem
Missing useful modern git settings.

### Additions to `git/.gitconfig`
```gitconfig
[rerere]
    enabled = true          # Remember merge conflict resolutions

[column]
    ui = auto               # Column output for branch listings

[branch]
    sort = -committerdate   # Most recent branches first

[fetch]
    prune = true            # Auto-delete stale remote branches

[diff]
    algorithm = histogram   # Better diff algorithm
    colorMoved = default    # Highlight moved lines differently

[transfer]
    fsckobjects = true      # Verify integrity on fetch/push

[includeIf "gitdir:~/work/"]
    path = ~/dotfiles/git/.gitconfig-work
```

The `includeIf` pattern allows a separate work identity (different email) without manual switching.

---

## 8. Ansible Role for Dotfiles Install Script

### Problem
The `dotfiles` ansible role clones the repo and symlinks `~/.zshrc`. But if you're on a machine without ansible (a server, a container, a friend's laptop), there's no quick setup.

### Add `install.sh` to dotfiles root
A standalone script that:
1. Detects OS
2. Creates all symlinks (zshrc, gitconfig, tmux.conf, nvim, alacritty, etc.)
3. Installs Oh My Zsh if missing
4. Copies `local-overrides.template` if no `local-overrides` exists
5. Is idempotent (safe to re-run)

This mirrors what the ansible `dotfiles` + `git_config` + `tmux` + `neovim` + `alacritty_config` + `vscode_config` + `cursor_config` + `claude` roles do, but as a single portable shell script.

Benefits:
- Quick setup without ansible
- Useful for containers and CI
- The ansible roles can call this script instead of duplicating symlink logic

---

## 9. Starship Prompt

### Problem
`sonicradish` is a basic Oh My Zsh theme. It doesn't show git status, language versions, exit codes, or AWS profile — all things you'd benefit from seeing.

### Proposal
Replace with [Starship](https://starship.rs/):
- Rust-based, extremely fast
- Shows: git branch + status + stash, node/python/go versions, AWS profile, exit code, command duration
- Single `starship.toml` config file versioned in dotfiles
- Works across zsh, bash, fish

### Changes
- **dotfiles**: Add `starship/starship.toml`, remove `ZSH_THEME` from zshrc, add `eval "$(starship init zsh)"`.
- **ansible-recipes**: Add starship binary install to `modern_cli_tools` role (or new `starship` role). Available via Homebrew on macOS.

---

## 10. Atuin: Shell History on Steroids

### Problem
Default shell history is limited, unsearchable across machines, and lost on terminal close if not flushed.

### Proposal
[Atuin](https://atuin.sh/) replaces Ctrl+R with:
- SQLite-backed searchable history
- Filter by directory, host, exit code, time
- Optional encrypted sync across machines
- Full-text search with fuzzy matching

### Changes
- **ansible-recipes**: New role to install atuin binary.
- **dotfiles**: Add `eval "$(atuin init zsh)"` to zshrc. Add `atuin/config.toml` for settings.

---

## 11. Cron Jobs → Systemd Timers (Linux)

### Problem
Cron jobs (defined in ansible `crontab` role) have no logging, no failure notifications, and are invisible to `systemctl status`.

### Proposal
Convert the 8 cron jobs to systemd user timers:
- Visible via `systemctl --user status`
- Logs via `journalctl --user -u clean-downloads.timer`
- Dependency ordering (e.g., network-online for sync-github)
- Can send failure notifications via `OnFailure=`

### Changes
- **ansible-recipes**: New role `systemd_timers` with `.service` and `.timer` unit files.
- **dotfiles**: Store the unit files in `systemd/` directory (new).
- Keep cron as fallback for macOS (no systemd).

---

## 12. Consolidate Duplicate Logic Between Projects

### Problem
Some logic is duplicated between ansible roles and dotfiles:
- Ansible clones oh-my-zsh AND dotfiles sources it
- Ansible creates symlinks for 10+ files across 7 roles — fragile, easy to miss one
- Package lists in ansible but tool-specific config in dotfiles — no single place to see "what's installed and configured"

### Proposal
- Add `install.sh` to dotfiles (item 8) and have ansible call it via `shell: ~/dotfiles/install.sh`
- Keep package installation in ansible (that's its job)
- Keep configuration in dotfiles (that's its job)
- Document the boundary clearly in both READMEs

---

## Priority Matrix

| #  | Improvement                        | Effort | Impact | Where            |
|----|------------------------------------|--------|--------|------------------|
| 2  | Discoverability (aliases + tools)  | Low    | High   | dotfiles         |
| 5  | zsh-autosuggestions + highlighting | Low    | High   | both             |
| 1  | Modern CLI tools                   | Medium | High   | both             |
| 3  | delta git pager                    | Low    | Medium | dotfiles         |
| 7  | Git config improvements            | Low    | Medium | dotfiles         |
| 4  | Shell startup performance          | Low    | Medium | dotfiles         |
| 6  | SSH config                         | Low    | Medium | both             |
| 8  | Dotfiles install script            | Medium | Medium | dotfiles         |
| 9  | Starship prompt                    | Medium | Medium | both             |
| 10 | Atuin shell history                | Medium | Medium | both             |
| 12 | Consolidate duplicate logic        | Medium | Medium | both             |
| 11 | Systemd timers                     | High   | Low    | both             |
