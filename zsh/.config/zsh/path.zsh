# Version managers and PATH. Order matters.

# --- mise (manages ruby + node; versions in ~/.config/mise/config.toml) ---
# Shims, not `mise activate`. activate works through a precmd hook, which
# Claude Code's cached shell snapshot drops (the same failure as zoxide's chpwd
# hook in .zshrc), leaving ruby unresolved there. Shims are a plain PATH entry,
# so they work in every shell, script and editor. Per-project mise.toml,
# .tool-versions and .nvmrc files are still honoured - the shim resolves at
# exec time.
#
# Must come before Homebrew's bin on PATH: Homebrew's node (a transitive dep of
# gemini-cli) is broken - it links libada.3.dylib but ada-url ships libada.4.
# .zshrc sources this file after adding Homebrew, so the shim wins.
[[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"
