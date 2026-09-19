# dotfiles

Terminal setup for AI-assisted development. Ghostty + zsh + Starship + Atuin,
managed with GNU Stow.

## New machine

```sh
git clone <this-repo> ~/code/dotfiles
~/code/dotfiles/bootstrap.sh
exec zsh
```

`bootstrap.sh` is idempotent — re-run it any time.

## What's here

| Package    | Links to                     | What it is                          |
| ---------- | ---------------------------- | ----------------------------------- |
| `zsh/`     | `~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.config/zsh/` | Shell config |
| `ghostty/` | `~/.config/ghostty/config`   | Terminal: Dracula, Nerd Font, keybinds |
| `starship/`| `~/.config/starship.toml`    | Prompt                              |
| `atuin/`   | `~/.config/atuin/config.toml`| Shell history, owns <kbd>Ctrl</kbd>+<kbd>R</kbd> |
| `ripgrep/` | `~/.config/ripgrep/ripgreprc`| Search defaults + clickable results |
| `git/`     | `~/.gitconfig`, `~/.gitignore_global` | Git (identity lives outside the repo — see below) |
| `mise/`    | `~/.config/mise/config.toml` | Global tool versions (node)       |

Stow one package: `stow --dir=~/code/dotfiles --target=~ --restow zsh`

## Keys

| Key | Does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | Atuin history search |
| <kbd>↑</kbd> | Previous command (plain zsh — deliberately *not* Atuin) |
| <kbd>Ctrl</kbd>+<kbd>T</kbd> / <kbd>Alt</kbd>+<kbd>C</kbd> | fzf file / directory |
| <kbd>Shift</kbd>+<kbd>Enter</kbd> | Newline in Claude Code |
| <kbd>Cmd</kbd>+<kbd>D</kbd> / <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> | Split right / down |
| <kbd>Cmd</kbd>+<kbd>↑</kbd> / <kbd>Cmd</kbd>+<kbd>↓</kbd> | Jump to previous / next prompt |
| <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>,</kbd> | Reload Ghostty config |

## Cmd+click on files

Ghostty 1.3.1 **cannot** be configured to match bare file paths — the `link`
option is documented but marked *"TODO: This can't currently be set!"*, and its
built-in matcher only handles a hard-coded scheme list. Clickable paths come
from tools emitting OSC 8 hyperlinks instead:

- `ls` / `ll` / `lt` → `eza --hyperlink=always`, but only when stdout is a
  terminal. eza's own `--hyperlink=auto` never emits, and an unconditional
  `always` would leak escape codes into every pipe — hence the wrapper
  functions in `zsh/.config/zsh/aliases.zsh`.
- `rg` → `--hyperlink-format=vscode` in `ripgreprc`, so hits open at the exact
  line and column.

**This does not work on arbitrary program output**, including Claude Code's own
— it colours paths with SGR escapes rather than emitting OSC 8 links.

File types open in VS Code via `duti`. Bindings must be set **by UTI**, not by
extension: `duti -s com.microsoft.VSCode .py all` reports success and is then
ignored by LaunchServices. `.go`, `.rs`, `.jsx`, `.tf` and `.conf` have no
declared UTI (macOS assigns a dynamic `dyn.*` type) and cannot be rebound at
all; they fall to whichever app declares the extension.

Roll back the associations with `scripts/restore-file-associations.sh`.

## Git identity

The tracked `git/.gitconfig` carries no identity. The same file lands on a work
laptop and a personal one, so anything machine-specific — `user.email`,
credential helpers with absolute Homebrew paths, `safe.directory` — lives in
`~/.gitconfig.local`, which is neither tracked nor stowed.

```ini
# ~/.gitconfig.local  (create by hand on each new machine)
[user]
	name = AJ Moore
	email = you@example.com
[credential "https://github.com"]
	helper =
	helper = !/opt/homebrew/bin/gh auth git-credential
[safe]
	directory = *
```

The `[include]` that pulls it in **must stay last** in `git/.gitconfig`. Git
applies values in file order and the last one wins, so an include placed higher
would be silently overridden by whatever follows it.

Check it resolved the way you think with `git config --show-origin --get user.email`.

**This repo is itself an exception**, and in two ways — both of which live in
the untracked `.git/config`, so a fresh clone silently reverts to the work
identity. Run both right after cloning:

```sh
cd ~/code/dotfiles

# 1. Author commits as the personal address, not the machine default.
git config user.email ajmoore.xyz@gmail.com

# 2. Push as the personal GitHub account.
git remote set-url origin git@github.com:ajmoorexyz/dotfiles.git
git config core.sshCommand \
  'ssh -o IdentityAgent="\"$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"" -o IdentitiesOnly=yes -i "$HOME/.config/git/ajmoorexyz.pub"'
```

Both SSH keys live in 1Password and are served by its agent; the private key
never touches disk. `~/.config/1Password/ssh/agent.toml` lists `disco` first,
so the *default* github.com identity stays the work account — `ssh -T
git@github.com` answers `Hi ajmoore-csdisco!`. This repo overrides that by
pinning one key with `IdentitiesOnly` plus the matching **public** key at
`~/.config/git/ajmoorexyz.pub` (write that file on a new machine; the value is
in the 1Password item `personal`, field `public key`).

Two things that will waste your time otherwise:

- The agent socket path contains spaces, and `ssh -o IdentityAgent=...` will
  not accept them unquoted — it fails with *"keyword identityagent extra
  arguments at end of line"*. The value needs quotes **inside** the `-o`
  argument, hence the escaped pair above.
- HTTPS is not a workable alternative here. `gh auth git-credential` serves
  whichever account is *active*, and ignores a username in the remote URL, so
  an HTTPS push either 403s as the work account or falls through to a password
  prompt. Pushing over HTTPS means `gh auth switch` every time.

Verify with `ssh -o ... -T git@github.com`, which should answer `Hi ajmoorexyz!`.

The general version of this problem — every personal repo, not just this one —
wants `includeIf "gitdir:..."` in `git/.gitconfig`, which needs work and
personal repos in separate directory trees. Not done: everything is under
`~/code` today.

## What does not belong in this repo

**This repo is public.** `~/.zshrc` sources `~/.zshrc.local` last, and that
file is neither tracked nor stowed. Employer hostnames, internal paths,
account names, API tokens and job-specific helper functions go there.

On a new machine nothing in `~/.zshrc.local` exists, so anything depending on
it fails quietly — an empty `$TG_TF_PATH`, a missing `$JIRA_API_TOKEN`, a
`wb: command not found`. That is the intended trade: the repo stays generic
and portable, and the machine-specific half is recreated deliberately.

Tokens in there are plaintext on disk (`chmod 600`), which is what the
pre-Starship `~/.zshrc` did too. Better would be to fetch them from 1Password
at use time rather than export them into every shell:

```sh
export JIRA_API_TOKEN="$(op read 'op://Personal/jira-api/credential')"
```

That costs a biometric prompt per shell, so it is a deliberate trade-off, not
an obvious win. Not done.

## Notes

- **Ghostty's colours are generated from iTerm, not picked from a theme list.**
  `theme = iterm` reads `ghostty/.config/ghostty/themes/iterm`, which
  `scripts/sync-iterm-theme.sh` writes from iTerm's *live* colours. Re-run it
  after changing anything in iTerm's colour settings.

  No shipped theme matches, so don't try to substitute one. iTerm here is a
  modified Dracula: palette 0 is `#000000` (stock `#21222c`), 7 is `#bbbbbb`
  (`#f8f8f2`), 8 is `#555555` (`#6272a4`), the background is `#1e1f29`
  (`#282a36`), and brights 9–14 are identical to the normal colours rather
  than lightened. `Dracula` and `Dracula+` are both visibly wrong — and those
  two are not the same palette as each other either.

  The script reads AppleScript, **not** `com.googlecode.iterm2.plist`. iTerm
  holds preferences in memory and flushes on quit, so the plist is routinely
  stale — ours was missing an entire profile and its `Background Color`
  disagreed with both the `(Light)` and `(Dark)` variants stored beside it.
  Only the running app knows what is actually on screen.

- **Ghostty reads a second config, and it wins.** On macOS it loads
  `~/.config/ghostty/config` *and*
  `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`, plus
  `auto/theme.ghostty` in that same directory — which Ghostty's own settings
  UI writes whenever you pick a theme in the app. Application Support loads
  last, so it silently overrides this repo. That is not a merge failure you
  will notice: the repo's `font-family` and padding applied normally while
  `theme` was quietly replaced with `iTerm2 Solarized Light`.

  Check with `ghostty +show-config | grep -E '^(theme|background)'`, which
  prints the *resolved* value rather than what any one file says. Those two
  files have had their `theme` lines removed on this machine, but changing the
  theme in Ghostty's UI will write `auto/theme.ghostty` again and re-break it.

  To verify what is actually rendered rather than what is configured, ask the
  terminal itself — it answers OSC colour queries:

  ```sh
  printf '\033]11;?\033\\'   # background; replies rgb:1e1e/1f1f/2929
  ```
- **`compinit` refuses to run if anything in `fpath` is group-writable**, and
  `/opt/homebrew/share` ships that way (`drwxrwxr-x`). When it bails, `compdef`
  is never defined and every prompt prints
  `compdef: unknown command or service: kubectl`. Fix the cause:
  `chmod g-w /opt/homebrew/share`, then `rm ~/.cache/zsh/zcompdump` — the dump
  caches the broken state for 24h, so fixing perms alone looks like it did
  nothing. Verify with `compaudit` (silence is success).
- **No plugin manager.** `zsh-autosuggestions` and `zsh-syntax-highlighting`
  come from Homebrew and are sourced directly. Syntax highlighting must be
  sourced *last* or it fails to wrap widgets defined after it.
- **`atuin`, `herdr` and `mise` are not in the Brewfile**, because how they
  get installed depends on the architecture. `bootstrap.sh` branches on `uname -m`:
  - **arm64** — all three have Homebrew bottles, so it runs `brew install`. Fast and
    checksum-verified. This is the path you want.
  - **x86_64** — no bottles exist, and `brew install` would compile rustc from
    source (over an hour). It falls back to the vendors' prebuilt release
    binaries in `~/.local/bin`, verifying atuin's and mise's published SHA-256. **Herdr
    publishes no checksum, so on Intel that binary is installed unverified** —
    the script warns when it does this.
- **mise manages node, via shims rather than `mise activate`.**
  activate relies on a precmd hook that Claude Code's shell snapshot drops;
  shims are a plain `PATH` entry and work everywhere. Global versions live in
  `mise/.config/mise/config.toml`; project `mise.toml`, `.tool-versions` and
  `.nvmrc` files still override them. After changing a version, run
  `mise install`.
- Homebrew's `node` is broken on this machine (links `libada.3.dylib`, but the
  installed `ada-url` ships `libada.4`). It is only a transitive dependency of
  `gemini-cli`. mise's node shim comes first on `PATH` and shadows it, so
  nothing daily is affected.
- Shell startup: ~0.08s on arm64 (3-run median of
  `script -q /dev/null zsh -i -c exit`), down from ~0.96s under rad-shell. The
  earlier ~0.33s figure was measured on Intel.

## Rollback

Previous config is in `~/.config-backup-<date>/`. `~/.rad-shell` and
`~/.zgenom` are left on disk untouched — restoring is one `source` line.
