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

# CPU architecture, in Debian naming (amd64 / arm64). Prebuilt GitHub releases
# exist for every tool on amd64; on arm64 Walker and Elephant are built from source.
export OMBUNTU_ARCH="${OMBUNTU_ARCH:-$(dpkg --print-architecture 2>/dev/null || uname -m)}"
case "$OMBUNTU_ARCH" in
  amd64 | x86_64) OMBUNTU_ARCH=amd64 ;;
  arm64 | aarch64) OMBUNTU_ARCH=arm64 ;;
esac
export OMBUNTU_BUILD_FROM_SOURCE="${OMBUNTU_BUILD_FROM_SOURCE:-false}"

log() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# step <label> <script> [root]
step() {
  local label="$1" script="$2" mode="${3:-user}"
  echo
  log "$label"
  if [[ $mode == root ]]; then
    sudo --preserve-env=OMBUNTU_REPO,OMBUNTU_ARCH,OMBUNTU_BUILD_FROM_SOURCE,OMARCHY_PATH,OMARCHY_REF,OMARCHY_USER_ONLY,OMARCHY_SKIP_BASHRC,OMARCHY_FORCE_CONFIG \
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

# fetch <url> <dest>: download once, then require the file's SHA256 to match
# install/checksums.sha256. A pinned download with no entry, or a mismatch, aborts.
fetch() {
  local url="$1" dest="$2" name expected actual
  name=$(basename "$dest")
  [[ -s $dest ]] || curl -fsSL --retry 3 -o "$dest" "$url"
  expected=$(awk -v n="$name" '$2 == n {print $1}' "$OMBUNTU_REPO/install/checksums.sha256")
  [[ -n $expected ]] || die "No checksum recorded for $name in install/checksums.sha256"
  actual=$(sha256sum "$dest" | cut -d' ' -f1)
  if [[ $actual != "$expected" ]]; then
    rm -f "$dest"
    die "Checksum mismatch for $name (got $actual, expected $expected). Download removed; re-run to retry."
  fi
}
