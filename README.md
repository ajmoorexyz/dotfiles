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
| `git/`     | `~/.gitconfig`, `~/.gitignore_global` | Git                        |

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

## Notes

- **No plugin manager.** `zsh-autosuggestions` and `zsh-syntax-highlighting`
  come from Homebrew and are sourced directly. Syntax highlighting must be
  sourced *last* or it fails to wrap widgets defined after it.
- **`atuin` and `herdr` are not in the Brewfile.** Neither ships an x86_64
  bottle, so `brew install` compiles rustc from source (over an hour).
  `bootstrap.sh` fetches the vendors' prebuilt release binaries into
  `~/.local/bin` instead, verifying atuin's published SHA-256. Herdr publishes
  no checksum. On Apple Silicon, `brew install atuin herdr` works normally.
- **nvm is not used to select a version.** `nvm use default` is broken with the
  Homebrew nvm here, so `zsh/.config/zsh/path.zsh` puts the node bin directory
  on `PATH` directly and loads nvm with `--no-use` for on-demand switching.
- Homebrew's `node` is broken on this machine (links `libada.3.dylib`, but the
  installed `ada-url` ships `libada.4`). It is only a transitive dependency of
  `gemini-cli`. nvm's node shadows it, so nothing daily is affected.
- Shell startup: ~0.33s, down from ~0.96s under rad-shell.

## Rollback

Previous config is in `~/.config-backup-<date>/`. `~/.rad-shell` and
`~/.zgenom` are left on disk untouched — restoring is one `source` line.
