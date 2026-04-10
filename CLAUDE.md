# dotfiles — project instructions

## Repo layout

- `claude/CLAUDE.md` is the **canonical source** for the global `~/.claude/CLAUDE.md` — it gets deployed to `.files`. Do **not** put dotfiles-specific rules in it; it applies to every project.
- Dotfiles-specific guidance lives in this file (`dotfiles/CLAUDE.md`).

## Shell scripts (`bin/`)

Scripts in `~/dotfiles/bin/` run on **both Linux and macOS** — they must be portable across GNU and BSD userland.

Avoid GNU-only constructs that fail on macOS:

- `grep -P` (PCRE) → use `grep -E`, `sed`, or `awk`
- `grep -oP '... \K ...'` → use `sed -n 's/...//p'`
- `stat -c%s file` → use `stat -c%s file 2>/dev/null || stat -f%z file`
- `sed -i '...'` (GNU) vs `sed -i '' '...'` (BSD) → write to a temp file or detect OS
- `readlink -f`, `date -d`, `find -printf`, `xargs -r`, `truncate` — all GNU-only
- `wc -l` output has leading whitespace on BSD → pipe through `tr -d ' '`

When in doubt, stick to POSIX.
