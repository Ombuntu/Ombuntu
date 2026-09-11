#!/bin/bash
# Walker (launcher), Elephant (its data provider) and Satty (screenshot editor)
# are not in the Ubuntu archive. Install pinned releases into ~/.local/bin, building
# Walker and Elephant from source where no prebuilt binary exists (arm64).
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

# Asset names per architecture
case "$OMBUNTU_ARCH" in
  amd64) RUST_TRIPLE=x86_64-unknown-linux-gnu; MISE_ARCH=linux-x64 ;;
  arm64) RUST_TRIPLE=aarch64-unknown-linux-gnu; MISE_ARCH=linux-arm64 ;;
  *) die "Unsupported architecture: $OMBUNTU_ARCH" ;;
esac

# Walker and Elephant publish amd64 builds only; elsewhere (or on request) compile them.
if [[ $OMBUNTU_ARCH == amd64 && $OMBUNTU_BUILD_FROM_SOURCE != true ]]; then
  SOURCE_BUILD=false
else
  SOURCE_BUILD=true
  WALKER_STAMP="$WALKER_VERSION-src"
  ELEPHANT_STAMP="$ELEPHANT_VERSION-src"
fi
WALKER_STAMP="${WALKER_STAMP:-$WALKER_VERSION}"
ELEPHANT_STAMP="${ELEPHANT_STAMP:-$ELEPHANT_VERSION}"

clone_tag() { # clone_tag <repo-url> <tag> <dir>
  if [[ -d $3/.git ]] && [[ $(git -C "$3" describe --tags --exact-match 2>/dev/null) == "$2" ]]; then
    return 0
  fi
  rm -rf "$3"
  git clone -q --depth 1 --branch "$2" "$1" "$3"
}

# Walker
if [[ ! -x $BIN/walker || $(stamp walker) != "$WALKER_STAMP" ]]; then
  if [[ $SOURCE_BUILD == true ]]; then
    log "Walker $WALKER_VERSION (building from source with cargo, this takes a while)"
    command -v cargo >/dev/null || die "cargo is required to build Walker (sudo apt install cargo rustc, or run install.sh without --user-only)"
    clone_tag https://github.com/abenz1267/walker.git "$WALKER_VERSION" "$CACHE/src/walker"
    (cd "$CACHE/src/walker" && CARGO_TARGET_DIR="$CACHE/build/walker" cargo build --release --locked)
    install -m 755 "$CACHE/build/walker/release/walker" "$BIN/walker"
  else
    log "Walker $WALKER_VERSION"
    fetch "https://github.com/abenz1267/walker/releases/download/$WALKER_VERSION/walker-$WALKER_VERSION-$RUST_TRIPLE.tar.gz" "$CACHE/walker-$WALKER_VERSION.tar.gz"
    tar xzf "$CACHE/walker-$WALKER_VERSION.tar.gz" -C "$BIN" walker
    chmod +x "$BIN/walker"
  fi
  mark walker "$WALKER_STAMP"
fi

# Elephant + providers
if [[ ! -x $BIN/elephant || $(stamp elephant) != "$ELEPHANT_STAMP" ]]; then
  rm -f ~/.config/elephant/providers/*.so
  if [[ $SOURCE_BUILD == true ]]; then
    log "Elephant $ELEPHANT_VERSION (building from source with go)"
    command -v go >/dev/null || die "go is required to build Elephant (sudo apt install golang-go, or run install.sh without --user-only)"
    clone_tag https://github.com/abenz1267/elephant.git "$ELEPHANT_VERSION" "$CACHE/src/elephant"
    (
      cd "$CACHE/src/elephant"
      export CGO_ENABLED=1 GOFLAGS=-buildvcs=false
      go build -trimpath -ldflags="-s -w" -o "$BIN/elephant" ./cmd/elephant/elephant.go
      for p in "${ELEPHANT_PROVIDERS[@]}"; do
        go build -trimpath -ldflags="-s -w" -buildmode=plugin -o ~/.config/elephant/providers/"$p.so" "./internal/providers/$p"
      done
    )
  else
    log "Elephant $ELEPHANT_VERSION"
    fetch "https://github.com/abenz1267/elephant/releases/download/$ELEPHANT_VERSION/elephant-linux-amd64.tar.gz" "$CACHE/elephant-$ELEPHANT_VERSION.tar.gz"
    tar xzf "$CACHE/elephant-$ELEPHANT_VERSION.tar.gz" -C "$CACHE"
    install -m 755 "$CACHE/elephant-linux-amd64" "$BIN/elephant"
    for p in "${ELEPHANT_PROVIDERS[@]}"; do
      fetch "https://github.com/abenz1267/elephant/releases/download/$ELEPHANT_VERSION/$p-linux-amd64.tar.gz" "$CACHE/elephant-$p-$ELEPHANT_VERSION.tar.gz"
      tar xzf "$CACHE/elephant-$p-$ELEPHANT_VERSION.tar.gz" -C ~/.config/elephant/providers
    done
  fi
  mark elephant "$ELEPHANT_STAMP"
fi

# Satty
if [[ ! -x $BIN/satty || $(stamp satty) != "$SATTY_VERSION" ]]; then
  log "Satty $SATTY_VERSION"
  fetch "https://github.com/gabm/Satty/releases/download/$SATTY_VERSION/satty-$RUST_TRIPLE.tar.gz" "$CACHE/satty-$SATTY_VERSION.tar.gz"
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
  fetch "https://github.com/jdx/mise/releases/download/$MISE_VERSION/mise-$MISE_VERSION-$MISE_ARCH.tar.gz" "$CACHE/mise-$MISE_VERSION.tar.gz"
  mkdir -p "$CACHE/mise"
  tar xzf "$CACHE/mise-$MISE_VERSION.tar.gz" -C "$CACHE/mise"
  install -m 755 "$CACHE/mise/mise/bin/mise" "$BIN/mise"
  mark mise "$MISE_VERSION"
fi

# Ubuntu names these differently from Arch
[[ -x /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$BIN/bat"
[[ -x /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$BIN/fd"
true
