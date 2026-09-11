#!/bin/bash
# Walker (launcher), Elephant (its data provider) and Satty (screenshot editor)
# are not in the Ubuntu archive. Install pinned prebuilt releases into ~/.local/bin.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

WALKER_VERSION="${WALKER_VERSION:-v2.17.0}"
ELEPHANT_VERSION="${ELEPHANT_VERSION:-v2.22.0}"
SATTY_VERSION="${SATTY_VERSION:-v0.22.0}"
ELEPHANT_PROVIDERS=(desktopapplications calc clipboard files menus providerlist runner symbols websearch unicode bluetooth playerctl todo snippets bookmarks aptpackages)

BIN=~/.local/bin
CACHE=~/.cache/ombuntu
mkdir -p "$BIN" "$CACHE" ~/.config/elephant/providers

fetch() { # fetch <url> <dest>
  [[ -s $2 ]] || curl -fsSL --retry 3 -o "$2" "$1"
}

# Version stamps: walker cannot run until libgtk4-layer-shell is installed, so
# we track what was installed instead of asking the binaries.
stamp() { cat "$CACHE/$1.version" 2>/dev/null; }
mark() { echo "$2" >"$CACHE/$1.version"; }

# Walker
if [[ ! -x $BIN/walker || $(stamp walker) != "$WALKER_VERSION" ]]; then
  log "Walker $WALKER_VERSION"
  fetch "https://github.com/abenz1267/walker/releases/download/$WALKER_VERSION/walker-$WALKER_VERSION-x86_64-unknown-linux-gnu.tar.gz" "$CACHE/walker-$WALKER_VERSION.tar.gz"
  tar xzf "$CACHE/walker-$WALKER_VERSION.tar.gz" -C "$BIN" walker
  chmod +x "$BIN/walker"
  mark walker "$WALKER_VERSION"
fi

# Elephant + providers
if [[ ! -x $BIN/elephant || $(stamp elephant) != "$ELEPHANT_VERSION" ]]; then
  log "Elephant $ELEPHANT_VERSION"
  fetch "https://github.com/abenz1267/elephant/releases/download/$ELEPHANT_VERSION/elephant-linux-amd64.tar.gz" "$CACHE/elephant-$ELEPHANT_VERSION.tar.gz"
  tar xzf "$CACHE/elephant-$ELEPHANT_VERSION.tar.gz" -C "$CACHE"
  install -m 755 "$CACHE/elephant-linux-amd64" "$BIN/elephant"
  rm -f ~/.config/elephant/providers/*.so
  for p in "${ELEPHANT_PROVIDERS[@]}"; do
    fetch "https://github.com/abenz1267/elephant/releases/download/$ELEPHANT_VERSION/$p-linux-amd64.tar.gz" "$CACHE/elephant-$p-$ELEPHANT_VERSION.tar.gz"
    tar xzf "$CACHE/elephant-$p-$ELEPHANT_VERSION.tar.gz" -C ~/.config/elephant/providers
  done
  mark elephant "$ELEPHANT_VERSION"
fi

# Satty
if [[ ! -x $BIN/satty || $(stamp satty) != "$SATTY_VERSION" ]]; then
  log "Satty $SATTY_VERSION"
  fetch "https://github.com/gabm/Satty/releases/download/$SATTY_VERSION/satty-x86_64-unknown-linux-gnu.tar.gz" "$CACHE/satty-$SATTY_VERSION.tar.gz"
  mkdir -p "$CACHE/satty"
  tar xzf "$CACHE/satty-$SATTY_VERSION.tar.gz" -C "$CACHE/satty"
  install -m 755 "$CACHE/satty/satty" "$BIN/satty"
  mkdir -p ~/.local/share/applications
  cp -f "$CACHE/satty/satty.desktop" ~/.local/share/applications/
  mark satty "$SATTY_VERSION"
fi

# mise (Omarchy's dev-tool/version manager; the npx-style wrappers in ~/.local/bin rely on it)
MISE_VERSION="${MISE_VERSION:-v2026.9.5}"
if [[ ! -x $BIN/mise || $(stamp mise) != "$MISE_VERSION" ]]; then
  log "mise $MISE_VERSION"
  fetch "https://github.com/jdx/mise/releases/download/$MISE_VERSION/mise-$MISE_VERSION-linux-x64.tar.gz" "$CACHE/mise-$MISE_VERSION.tar.gz"
  mkdir -p "$CACHE/mise"
  tar xzf "$CACHE/mise-$MISE_VERSION.tar.gz" -C "$CACHE/mise"
  install -m 755 "$CACHE/mise/mise/bin/mise" "$BIN/mise"
  mark mise "$MISE_VERSION"
fi

# Ubuntu names these differently from Arch
[[ -x /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$BIN/bat"
[[ -x /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$BIN/fd"
true
