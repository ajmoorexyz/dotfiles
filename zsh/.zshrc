# ~/.zshrc - interactive shells.
# Managed in $DOTFILES (~/code/dotfiles). Edit there, not here.

ZSH_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
ZSH_COMPLETIONS="$ZSH_CACHE/completions"
mkdir -p "$ZSH_COMPLETIONS"

# ---------------------------------------------------------------- history ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY          # sync history across running shells
setopt EXTENDED_HISTORY       # record timestamp + duration
setopt HIST_IGNORE_ALL_DUPS   # keep only the most recent copy of a command
setopt HIST_IGNORE_SPACE      # a leading space keeps it out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # expand !! for review instead of running it

# ---------------------------------------------------------------- options ---
setopt AUTO_CD                # `foo` == `cd foo` for directories
setopt AUTO_PUSHD             # keep a directory stack
setopt PUSHD_IGNORE_DUPS
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS   # allow # comments when typing
setopt NO_BEEP

# ------------------------------------------------------------- completion ---
fpath=("$ZSH_COMPLETIONS" $fpath)
[[ -d "$HOMEBREW_PREFIX/share/zsh-completions" ]] \
  && fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)
[[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]] \
  && fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)

# kubectl completion is slow to generate, so cache it to a file rather than
# running `source <(kubectl completion zsh)` on every shell start. This must
# happen before compinit so the function is defined when compinit scans fpath.
if command -v kubectl >/dev/null; then
  if [[ ! -f "$ZSH_COMPLETIONS/_kubectl" ]] \
     || [[ "$(command -v kubectl)" -nt "$ZSH_COMPLETIONS/_kubectl" ]]; then
    kubectl completion zsh > "$ZSH_COMPLETIONS/_kubectl" 2>/dev/null
  fi
fi

autoload -Uz compinit
# Rebuild the dump at most once a day; use the cache otherwise. This is the
# single biggest win in shell startup time.
_zcompdump="$ZSH_CACHE/zcompdump"
if [[ -n "$_zcompdump"(#qN.mh+24) ]] || [[ ! -f "$_zcompdump" ]]; then
  compinit -d "$_zcompdump"
  touch "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE/zcompcache"

# `k` inherits kubectl's completions (compinit has run by now).
command -v kubectl >/dev/null && compdef k=kubectl


# ----------------------------------------------------------------- config ---
for _f in path aliases functions; do
  [[ -r "$HOME/.config/zsh/$_f.zsh" ]] && source "$HOME/.config/zsh/$_f.zsh"
done
unset _f

# ------------------------------------------------------------------ tools ---
# Prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# Smarter cd. `cd` is replaced by zoxide's frecency-ranked version.
command -v zoxide  >/dev/null && eval "$(zoxide init zsh --cmd cd)"

# Fuzzy finder: ctrl+t (files), alt+c (dirs). NOT ctrl+r - atuin owns that.
if command -v fzf >/dev/null; then
  source <(fzf --zsh) 2>/dev/null
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
  command -v fd >/dev/null && export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
fi

# Shell history: owns ctrl+r. --disable-up-arrow keeps plain up-arrow as the
# ordinary "previous command" you already have in your fingers.
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# ---------------------------------------------------------------- plugins ---
# Installed via Homebrew, sourced directly. No plugin manager.
[[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# MUST be last. zsh-syntax-highlighting wraps every widget defined before it;
# anything sourced after this point will not be highlighted correctly.
[[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
  && source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Machine-local overrides, never committed.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
