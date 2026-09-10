# ~/.zprofile - login shells. PATH and environment only.

# Homebrew. Handles both Intel (/usr/local) and Apple Silicon (/opt/homebrew)
# so this same file works on any Mac.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x "$_brew" ]]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew

# User binaries (claude lives here)
export PATH="$HOME/.local/bin:$PATH"
