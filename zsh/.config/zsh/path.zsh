# Version managers and PATH. Order matters.

# --- asdf (manages ruby on this machine) ---
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
[[ -d "$ASDF_DATA_DIR/shims" ]] && export PATH="$ASDF_DATA_DIR/shims:$PATH"

# --- nvm (manages node) ---
export NVM_DIR="$HOME/.nvm"

# Put nvm's node on PATH directly rather than calling `nvm use`.
#
# Two reasons. First, `nvm use default` is broken with this Homebrew nvm - the
# `default` alias points at `node` -> `stable`, and nvm reports it as "not yet
# installed". Second, Homebrew's node (a transitive dep of gemini-cli) is
# itself broken: it links libada.3.dylib but the installed ada-url ships
# libada.4. Without this, `node` resolves to that broken binary and aborts.
# A plain PATH prepend costs ~0ms and sidesteps both problems.
if [[ -d "$NVM_DIR/versions/node" ]]; then
  _nvm_pin="${NVM_DIR}/versions/node/$(<"$NVM_DIR/alias/default" 2>/dev/null)"
  if [[ -d "$_nvm_pin/bin" ]]; then
    export PATH="$_nvm_pin/bin:$PATH"          # default alias names a real version
  else
    _nvm_all=("$NVM_DIR"/versions/node/*(N/n)) # else: highest installed wins
    (( ${#_nvm_all} )) && export PATH="${_nvm_all[-1]}/bin:$PATH"
  fi
  unset _nvm_pin _nvm_all
fi

# Load nvm itself so `nvm install` / `nvm use` still work on demand.
if [[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]]; then
  source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" --no-use
elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh" --no-use
fi
