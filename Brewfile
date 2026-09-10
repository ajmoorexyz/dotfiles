# Brewfile - `brew bundle` from the repo root.
# NOTE: atuin and herdr are deliberately absent. Neither ships an Intel
# (x86_64) bottle, so `brew install` compiles rustc from source, which takes
# over an hour. bootstrap.sh fetches their official prebuilt release binaries
# instead. On Apple Silicon you can install both from brew normally.

# --- shell ---
brew "stow"                      # symlink manager for this repo
brew "starship"                  # prompt
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "zsh-completions"

# --- core CLI ---
brew "eza"                       # ls, with OSC 8 hyperlinks for cmd+click
brew "bat"                       # cat
brew "fd"                        # find
brew "ripgrep"                   # grep, with hyperlink support
brew "fzf"                       # fuzzy finder (ctrl+t, alt+c)
brew "zoxide"                    # cd
brew "jq"
brew "git"
brew "gh"

# --- macOS ---
brew "duti"                      # sets default app per file type

# --- apps ---
cask "ghostty"
cask "font-meslo-lg-nerd-font"
cask "visual-studio-code"
