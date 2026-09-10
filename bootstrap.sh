#!/usr/bin/env bash
# Bootstrap this machine's terminal setup. Idempotent - safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh ghostty starship atuin git ripgrep)

ATUIN_VERSION="v18.22.0"
HERDR_VERSION="v0.9.0"

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

# ----------------------------------------------- atuin + herdr (no bottles) ---
# Both are Rust and ship no x86_64 bottle; brew would build rustc from source.
# Use the vendors' official prebuilt binaries instead.
mkdir -p "$HOME/.local/bin"

install_atuin() {
  command -v atuin >/dev/null && return 0
  local arch tmp
  arch="$([[ "$(uname -m)" == "arm64" ]] && echo aarch64 || echo x86_64)"
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
  local arch tmp
  arch="$([[ "$(uname -m)" == "arm64" ]] && echo aarch64 || echo x86_64)"
  tmp="$(mktemp -d)"
  info "Installing herdr $HERDR_VERSION ($arch)"
  # Upstream publishes no checksum file for these assets.
  curl -fsSL -o "$tmp/herdr" \
    "https://github.com/herdrdev/herdr/releases/download/$HERDR_VERSION/herdr-macos-$arch"
  install -m 755 "$tmp/herdr" "$HOME/.local/bin/herdr"
  xattr -d com.apple.quarantine "$HOME/.local/bin/herdr" 2>/dev/null || true
  rm -rf "$tmp"
}

install_atuin || warn "atuin install failed"
install_herdr || warn "herdr install failed"

# ------------------------------------------------------------------- stow ---
# Move any real file that would block a symlink out of the way first.
info "Linking dotfiles"
BACKUP="$HOME/.dotfiles-pre-stow-$(date +%Y%m%d%H%M%S)"
for pkg in "${PACKAGES[@]}"; do
  while IFS= read -r rel; do
    target="$HOME/$rel"
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$target" "$BACKUP/$rel"
      warn "backed up existing $rel -> $BACKUP/$rel"
    fi
  done < <(cd "$DOTFILES/$pkg" && find . -type f | sed 's|^\./||')
done
stow --dir="$DOTFILES" --target="$HOME" --restow "${PACKAGES[@]}"

# ------------------------------------------------------------------ atuin ---
if command -v atuin >/dev/null; then
  if [[ -z "$(atuin history list 2>/dev/null | head -1)" ]]; then
    info "Importing existing shell history into atuin"
    atuin import auto || warn "atuin import found nothing to import"
  fi
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
  for uti in "${VSCODE_UTIS[@]}"; do
    duti -s com.microsoft.VSCode "$uti" all 2>/dev/null || true
  done
fi

# ------------------------------------------------------------------ herdr ---
# herdr runs its own server on demand - there is no brew service to start.
# `herdr` alone launches or attaches the persistent session.
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
