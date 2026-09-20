# shellcheck shell=bash
# Shared helpers for the installer steps

: "${HOME:?HOME must be set}"
# Defaults so each step can also be run on its own (install.sh exports these)
export OMBUNTU_REPO="${OMBUNTU_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export OMARCHY_PATH="${OMARCHY_PATH:-$HOME/.local/share/omarchy}"
export OMARCHY_REF="${OMARCHY_REF:-v3.8.4}"
export OMARCHY_COMMIT="${OMARCHY_COMMIT:-8fcc9d6048af4cb0e3af8512c78049857a3b53dd}"
export OMARCHY_UPSTREAM="${OMARCHY_UPSTREAM:-https://github.com/basecamp/omarchy.git}"
export OMARCHY_USER_ONLY="${OMARCHY_USER_ONLY:-false}"
export OMARCHY_SKIP_BASHRC="${OMARCHY_SKIP_BASHRC:-false}"
export OMARCHY_FORCE_CONFIG="${OMARCHY_FORCE_CONFIG:-false}"
export OMBUNTU_KEEP_TELEMETRY="${OMBUNTU_KEEP_TELEMETRY:-false}"
export OMBUNTU_KEEP_BROWSER_BUTTONS="${OMBUNTU_KEEP_BROWSER_BUTTONS:-false}"
export OMBUNTU_NO_FIREFOX_POLICY="${OMBUNTU_NO_FIREFOX_POLICY:-false}"
export OMBUNTU_NO_OOMD="${OMBUNTU_NO_OOMD:-false}"
# During the install, Omarchy's user-writable bin and ~/.local/bin go at the END of PATH:
# system tools (sha256sum, tar, curl, apt) must never be shadowed by a checkout we are
# about to fetch. Root steps get a fixed PATH in step() and never see these at all.
if (( EUID != 0 )); then
  export PATH="$PATH:$OMARCHY_PATH/bin:$HOME/.local/bin"
fi
export OMBUNTU_MANIFEST="$HOME/.local/state/ombuntu/manifest"

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
    # Root steps: explicit, system-only PATH; only installer flags are passed through.
    sudo --preserve-env=OMBUNTU_REPO,OMBUNTU_ARCH,OMBUNTU_BUILD_FROM_SOURCE,OMARCHY_REF,OMARCHY_COMMIT,OMARCHY_USER_ONLY,OMARCHY_SKIP_BASHRC,OMARCHY_FORCE_CONFIG,OMBUNTU_KEEP_TELEMETRY,OMBUNTU_KEEP_BROWSER_BUTTONS,OMBUNTU_NO_FIREFOX_POLICY,OMBUNTU_NO_OOMD \
      env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin bash "$script"
  else
    bash "$script"
  fi
}

# Record a path the installer created, so uninstall.sh removes only what we wrote.
record() {
  mkdir -p "$(dirname "$OMBUNTU_MANIFEST")"
  grep -qxF -- "$1" "$OMBUNTU_MANIFEST" 2>/dev/null || echo "$1" >>"$OMBUNTU_MANIFEST"
}

# Copy a file only if the destination is missing (or OMARCHY_FORCE_CONFIG=true).
# When forcing over an existing file, keep a .pre-omarchy backup the first time.
install_file() {
  local src="$1" dst="$2"
  if [[ -e $dst && $OMARCHY_FORCE_CONFIG != true ]]; then
    # Already there: if it is exactly what we would have written, it is ours (an earlier
    # run) and belongs in the manifest; a user-modified file is left unrecorded and untouched.
    cmp -s "$src" "$dst" && record "$dst"
    return 0
  fi
  if [[ -e $dst && ! -e $dst.pre-omarchy ]]; then
    cp -a "$dst" "$dst.pre-omarchy"
  fi
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  record "$dst"
}

# Recursively install a tree with install_file semantics.
install_tree() {
  local src="$1" dst="$2"
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$src"/}"
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
