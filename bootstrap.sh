#!/usr/bin/env bash
# Bootstrap this machine's terminal setup. Idempotent - safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh ghostty starship atuin git ripgrep mise)

# Only used on x86_64, where none of these has a Homebrew bottle. On arm64 the
# version comes from brew and these are ignored.
ATUIN_VERSION="v18.22.0"
HERDR_VERSION="v0.9.0"
MISE_VERSION="v2026.9.11"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- homebrew ---
if ! command -v brew >/dev/null; then
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x "$p" ]] && eval "$("$p" shellenv)" && break
done

info "Installing packages from Brewfile"
brew bundle --file="$DOTFILES/Brewfile"

# ------------------------------------------------ atuin + herdr + mise ---
# All three are Rust. On arm64 Homebrew has bottles for each, so `brew install`
# is a signed, checksum-verified download and takes seconds - always prefer
# it there. Only x86_64 lacks bottles, and only there does brew fall back to
# compiling rustc from source (over an hour); that is the case the curl path
# below exists for.
#
# The distinction matters for herdr specifically: upstream publishes no
# checksum for its release binaries, so the curl path installs an unverified
# executable. Taking that risk on a machine where a verified bottle exists
# would be gratuitous.
mkdir -p "$HOME/.local/bin"

# arm64 -> brew has bottles; x86_64 -> it does not.
HAS_BOTTLES=false
[[ "$(uname -m)" == "arm64" ]] && HAS_BOTTLES=true

install_atuin() {
  command -v atuin >/dev/null && return 0
  if [[ "$HAS_BOTTLES" == true ]]; then
    info "Installing atuin from Homebrew (arm64 bottle)"
    brew install atuin
    return
  fi
  local arch tmp
  arch="x86_64"
  tmp="$(mktemp -d)"
  info "Installing atuin $ATUIN_VERSION ($arch)"
  curl -fsSL -o "$tmp/a.tar.gz" \
    "https://github.com/atuinsh/atuin/releases/download/$ATUIN_VERSION/atuin-$arch-apple-darwin.tar.gz"
  curl -fsSL -o "$tmp/a.sha256" \
    "https://github.com/atuinsh/atuin/releases/download/$ATUIN_VERSION/atuin-$arch-apple-darwin.tar.gz.sha256"
  local expected actual
  expected="$(awk '{print $1}' "$tmp/a.sha256")"
  actual="$(shasum -a 256 "$tmp/a.tar.gz" | awk '{print $1}')"
  [[ "$expected" == "$actual" ]] || { warn "atuin checksum mismatch, skipping"; return 1; }
  tar xzf "$tmp/a.tar.gz" -C "$tmp"
  install -m 755 "$tmp/atuin-$arch-apple-darwin/atuin" "$HOME/.local/bin/atuin"
  xattr -d com.apple.quarantine "$HOME/.local/bin/atuin" 2>/dev/null || true
  rm -rf "$tmp"
}

install_herdr() {
  command -v herdr >/dev/null && return 0
  if [[ "$HAS_BOTTLES" == true ]]; then
    info "Installing herdr from Homebrew (arm64 bottle)"
    brew install herdr
    return
  fi
  local arch tmp
  arch="x86_64"
  tmp="$(mktemp -d)"
  warn "herdr publishes no checksum for its release binaries - installing unverified"
  info "Installing herdr $HERDR_VERSION ($arch)"
  curl -fsSL -o "$tmp/herdr" \
    "https://github.com/herdrdev/herdr/releases/download/$HERDR_VERSION/herdr-macos-$arch"
  install -m 755 "$tmp/herdr" "$HOME/.local/bin/herdr"
  xattr -d com.apple.quarantine "$HOME/.local/bin/herdr" 2>/dev/null || true
  rm -rf "$tmp"
}

install_mise() {
  command -v mise >/dev/null && return 0
  if [[ "$HAS_BOTTLES" == true ]]; then
    info "Installing mise from Homebrew (arm64 bottle)"
    brew install mise
    return
  fi
  local arch tmp name
  arch="x64"
  name="mise-$MISE_VERSION-macos-$arch"
  tmp="$(mktemp -d)"
  info "Installing mise $MISE_VERSION ($arch)"
  curl -fsSL -o "$tmp/$name" \
    "https://github.com/jdx/mise/releases/download/$MISE_VERSION/$name"
  curl -fsSL -o "$tmp/SHASUMS256.txt" \
    "https://github.com/jdx/mise/releases/download/$MISE_VERSION/SHASUMS256.txt"
  local expected actual
  expected="$(awk -v f="./$name" -v g="$name" '$2 == f || $2 == g {print $1}' "$tmp/SHASUMS256.txt")"
  actual="$(shasum -a 256 "$tmp/$name" | awk '{print $1}')"
  [[ -n "$expected" && "$expected" == "$actual" ]] || { warn "mise checksum mismatch, skipping"; return 1; }
  install -m 755 "$tmp/$name" "$HOME/.local/bin/mise"
  xattr -d com.apple.quarantine "$HOME/.local/bin/mise" 2>/dev/null || true
  rm -rf "$tmp"
}

install_atuin || warn "atuin install failed"
install_herdr || warn "herdr install failed"
install_mise  || warn "mise install failed"

# ------------------------------------------------------------------- stow ---
# Move any real file that would block a symlink out of the way first.
info "Linking dotfiles"
BACKUP="$HOME/.dotfiles-pre-stow-$(date +%Y%m%d%H%M%S)"
for pkg in "${PACKAGES[@]}"; do
  while IFS= read -r rel; do
    target="$HOME/$rel"
    [[ -e "$target" ]] || continue
    [[ -L "$target" ]] && continue

    # `-L` only tests the FINAL path component, which is not enough once stow
    # has run. Stow folds a directory it owns entirely into a single symlink
    # (~/.config/zsh -> <repo>/zsh/.config/zsh), so ~/.config/zsh/aliases.zsh
    # is a real, non-symlink file reached *through* that link - and the naive
    # check would happily `mv` this repo's own tracked files into the backup
    # directory, deleting them from the working tree. Resolve the parent and
    # skip anything that already lives inside $DOTFILES.
    resolved="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)/$(basename "$target")"
    [[ "$resolved" == "$DOTFILES"/* ]] && continue

    mkdir -p "$BACKUP/$(dirname "$rel")"
    mv "$target" "$BACKUP/$rel"
    warn "backed up existing $rel -> $BACKUP/$rel"
  done < <(cd "$DOTFILES/$pkg" && find . -type f | sed 's|^\./||')
done
stow --dir="$DOTFILES" --target="$HOME" --restow "${PACKAGES[@]}"

# ------------------------------------------------------------------- mise ---
# Installs the ruby and node pinned in ~/.config/mise/config.toml, which stow
# has just linked. Ruby compiles from source (~5 min on Intel); node is a
# prebuilt download. Already-installed versions are skipped, so re-runs are
# instant. ~/.local/bin is checked explicitly because on x86_64 that is where
# install_mise put the binary, and it may not be on this script's PATH.
_mise="$(command -v mise || true)"
[[ -z "$_mise" && -x "$HOME/.local/bin/mise" ]] && _mise="$HOME/.local/bin/mise"
if [[ -n "$_mise" ]]; then
  info "Installing mise tool versions"
  (cd "$HOME" && "$_mise" install) || warn "mise install failed"
fi
unset _mise

# ------------------------------------------------------------------ atuin ---
if command -v atuin >/dev/null; then
  # Test the database directly, not `atuin history list`. That command needs
  # $ATUIN_SESSION, which only exists inside a shell where `atuin init` has
  # run - never here - so it always errored to empty and the import always
  # re-ran. Harmless, since atuin's import deduplicates, but it made an
  # idempotent-looking guard that never actually guarded anything.
  _atuin_db="${XDG_DATA_HOME:-$HOME/.local/share}/atuin/history.db"
  if [[ ! -s "$_atuin_db" ]]; then
    info "Importing existing shell history into atuin"
    atuin import auto || warn "atuin import found nothing to import"
  fi
  unset _atuin_db
fi

# ------------------------------------------------ default apps for cmd+click ---
# Makes OSC 8 file:// links from `ls` open in VS Code rather than whatever
# macOS picked. Bindings MUST be by UTI, not by extension: `duti -s <id> .py`
# reports success but LaunchServices ignores it on current macOS.
#
# Not fixable here: .go .rs .jsx .tf .conf have no declared UTI (macOS assigns
# a dynamic `dyn.*` type), and those resolve to whichever installed app claims
# the extension. Overriding them is not possible via duti.
VSCODE_UTIS=(
  public.python-script public.ruby-script public.shell-script public.bash-script
  public.zsh-script com.fishshell.script public.perl-script public.php-script
  org.lua public.swift-source com.sun.java-source
  public.c-source public.c-header public.c-plus-plus-source public.c-plus-plus-header
  com.netscape.javascript-source com.microsoft.typescript public.mpeg-2-transport-stream
  public.json public.yaml public.toml com.microsoft.ini public.xml public.css
  net.daringfireball.markdown net.ia.markdown org.iso.sql
  public.plain-text com.apple.log
)
if command -v duti >/dev/null && [[ -d "/Applications/Visual Studio Code.app" ]]; then
  info "Pointing code file types at VS Code"
  # A UTI no installed app declares cannot be bound, and duti fails on it.
  # That is expected, not an error - but report the count rather than
  # swallowing it, so a genuine breakage is not mistaken for a clean run.
  # On a stock machine roughly 7 of these are undeclared (fish, lua,
  # ia-markdown, typescript, toml, ini, sql). Most of their extensions still
  # resolve to VS Code anyway, because nothing else claims them.
  _duti_skipped=()
  for uti in "${VSCODE_UTIS[@]}"; do
    duti -s com.microsoft.VSCode "$uti" all 2>/dev/null || _duti_skipped+=("$uti")
  done
  if (( ${#_duti_skipped[@]} )); then
    warn "${#_duti_skipped[@]}/${#VSCODE_UTIS[@]} UTIs undeclared on this machine, skipped:"
    printf '      %s\n' "${_duti_skipped[@]}"
  fi
  unset _duti_skipped
fi

# ------------------------------------------------------------------ herdr ---
# `herdr` alone launches or attaches the persistent session, starting the
# server on demand - nothing needs starting here.
#
# The Homebrew formula does also ship a launchd service (`brew services start
# herdr`, or `herdr server` in the foreground). That is only worth it if you
# want the server resident before the first client connects; on-demand start
# is the default and is what this setup relies on.
if command -v herdr >/dev/null; then
  mkdir -p "$HOME/.cache/zsh/completions"
  herdr completion zsh > "$HOME/.cache/zsh/completions/_herdr" 2>/dev/null || true
  info "herdr $(herdr --version 2>/dev/null | awk '{print $2}') ready - run 'herdr' to start a session"
fi

# ----------------------------------------------------------------- manual ---
cat <<'MANUAL'

==> Done. Remaining manual steps:

  1. Set Ghostty as your default terminal
       Ghostty > Settings, or right-click Ghostty.app > Get Info
  2. Restart your shell:   exec zsh
  3. Connect Claude Code to herdr (adds a hook to ~/.claude/settings.json):
       herdr integration install claude
  4. Optional - enable atuin history sync across machines:
       atuin register -u <username> -e <email>
       atuin sync
  5. Optional - remove the old setup once you are happy:
       rm -rf ~/.rad-shell ~/.zgenom ~/.zgen.bak ~/.p10k.zsh ~/.config/oh-my-posh

MANUAL
