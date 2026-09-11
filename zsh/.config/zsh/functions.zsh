# Functions. Migrated from ajmoorexyz/rad-plugins + old ~/.zshrc.

### md - make a directory and cd into it
md() {
  mkdir -p -- "$1" && builtin cd -P -- "$1"
}

### git-rebase - sync origin/<branch> with upstream/<branch>
git-rebase() {
  local branch="${1:-main}"
  git checkout "$branch" &&
  git fetch upstream --prune &&
  git rebase "upstream/${branch}" &&
  git push origin "$branch"
}

### decode-sts - decode an AWS STS authorization failure message
decode-sts() {
  aws sts decode-authorization-message --encoded-message "$1" --output text | jq .
}

### edit.zshrc - open the dotfiles repo in VS Code
edit.zshrc() {
  code -n "$DOTFILES"
}

### hlink - print a path as an OSC 8 hyperlink, so it is cmd+clickable
# Usage: hlink ./some/file.ts     |     somecmd | while read f; do hlink "$f"; done
hlink() {
  local target="${1:?usage: hlink <path>}"
  local abs="${target:A}"
  printf '\e]8;;file://%s\e\\%s\e]8;;\e\\\n' "$abs" "$target"
}
