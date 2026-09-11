# Shared helpers for the installer steps

# Defaults so each step can also be run on its own (install.sh exports these)
export OMBUNTU_REPO="${OMBUNTU_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export OMARCHY_PATH="${OMARCHY_PATH:-$HOME/.local/share/omarchy}"
export OMARCHY_REF="${OMARCHY_REF:-v3.8.4}"
export OMARCHY_UPSTREAM="${OMARCHY_UPSTREAM:-https://github.com/basecamp/omarchy.git}"
export OMARCHY_USER_ONLY="${OMARCHY_USER_ONLY:-false}"
export OMARCHY_SKIP_BASHRC="${OMARCHY_SKIP_BASHRC:-false}"
export OMARCHY_FORCE_CONFIG="${OMARCHY_FORCE_CONFIG:-false}"
export PATH="$OMARCHY_PATH/bin:$HOME/.local/bin:$PATH"

log() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# step <label> <script> [root]
step() {
  local label="$1" script="$2" mode="${3:-user}"
  echo
  log "$label"
  if [[ $mode == root ]]; then
    sudo --preserve-env=OMBUNTU_REPO,OMARCHY_PATH,OMARCHY_REF,OMARCHY_USER_ONLY,OMARCHY_SKIP_BASHRC,OMARCHY_FORCE_CONFIG \
      bash "$script"
  else
    bash "$script"
  fi
}

# Copy a file only if the destination is missing (or OMARCHY_FORCE_CONFIG=true).
# When forcing over an existing file, keep a .pre-omarchy backup the first time.
install_file() {
  local src="$1" dst="$2"
  if [[ -e $dst && $OMARCHY_FORCE_CONFIG != true ]]; then
    return 0
  fi
  if [[ -e $dst && ! -e $dst.pre-omarchy ]]; then
    cp -a "$dst" "$dst.pre-omarchy"
  fi
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
}

# Recursively install a tree with install_file semantics.
install_tree() {
  local src="$1" dst="$2"
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#$src/}"
    install_file "$f" "$dst/$rel"
  done < <(find "$src" -type f -print0)
}

# Install a systemd user unit from a file, then daemon-reload.
install_user_unit() {
  local src="$1" name="$2"
  mkdir -p ~/.config/systemd/user
  cp -f "$src" ~/.config/systemd/user/"$name"
}
