#!/bin/bash
# JetBrainsMono Nerd Font (Omarchy's UI/terminal font) and the Omarchy icon font.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

NERD_FONTS_VERSION="${NERD_FONTS_VERSION:-v3.5.1}"
FONTS=~/.local/share/fonts
CACHE=~/.cache/ombuntu
mkdir -p "$FONTS" "$CACHE"

if (( $(fc-list | grep -c "JetBrainsMono Nerd Font") == 0 )); then
  log "JetBrainsMono Nerd Font $NERD_FONTS_VERSION"
  fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONTS_VERSION/JetBrainsMono.tar.xz" "$CACHE/JetBrainsMono-$NERD_FONTS_VERSION.tar.xz"
  mkdir -p "$FONTS/JetBrainsMonoNerdFont"
  tar xJf "$CACHE/JetBrainsMono-$NERD_FONTS_VERSION.tar.xz" -C "$FONTS/JetBrainsMonoNerdFont"
fi

if [[ -f $OMARCHY_PATH/config/omarchy.ttf ]]; then
  cp -f "$OMARCHY_PATH/config/omarchy.ttf" "$FONTS/"
fi

fc-cache -f >/dev/null
