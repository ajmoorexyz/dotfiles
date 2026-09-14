# Aliases. Migrated from ajmoorexyz/rad-plugins + old ~/.zshrc.

### c - open the current directory in VS Code
alias c="code -n ."
### co - jump to the projects dir
alias co="cd $PROJECTS_DIR"

# --- search helpers ---
### grh - search shell history
alias grh="history 0 | grep -i"
### gral - search aliases  (was `gra`, which collided with `git remote add`)
alias gral="alias | grep -i"
### gre - search environment variables
alias gre="env | grep -i"

# --- git ---
alias ga="git add"
alias gaa="git add --all"
alias gb="git branch"
alias gca="gaa && git commit --amend"
alias gcb="git checkout -b"
alias gcl="git clone"
alias gcm="gco main"
alias gcmsg="gaa && git commit -m"
alias gco="git checkout"
alias ggpush="git push origin HEAD"
alias gra="git remote add"
alias grau="git remote add upstream"
alias grv="git remote -v"
alias gs="git status -sb"
alias gl="git log --oneline --graph --decorate -20"
### glo - one-line-per-commit log. Inlined from Prezto's version so it
### survived Prezto's removal rather than silently disappearing with it.
alias glo='git log --topo-order --pretty=format:"%C(green)%h%C(reset) %s%C(red)%d%C(reset)%n"'

# --- kubernetes ---
alias k=kubectl

# --- aws ---
### aws-clear - drop every AWS credential/region var from this shell.
### Stale AWS_* env vars silently override AWS_PROFILE, which produces
### confusing "wrong account" failures rather than an obvious error.
alias aws-clear="unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_REGION AWS_DEFAULT_REGION && echo 'AWS credentials unset.'"

# --- modern CLI replacements ---
# ls/ll/lt are functions, not aliases, so OSC 8 hyperlinks (which make files
# cmd+clickable in Ghostty) are emitted ONLY when writing to a terminal.
# eza's own `--hyperlink=auto` does not work - as of 0.23.5 it never emits -
# and a bare `--hyperlink=always` would leak escape codes into every pipe.
_eza_hyper() {
  if [[ -t 1 ]]; then
    eza --hyperlink=always "$@"
  else
    eza "$@"
  fi
}
ls() { _eza_hyper --icons --group-directories-first "$@"; }
ll() { _eza_hyper --icons --group-directories-first -lah --git "$@"; }
lt() { _eza_hyper --icons --tree --level=2 "$@"; }

alias cat="bat --paging=never"
alias grep="grep --color=auto"

# Real `ls` when a script or muscle memory needs it
alias lsx="command ls"
