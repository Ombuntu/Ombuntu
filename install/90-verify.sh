#!/bin/bash
# Parse the generated Hyprland configuration without starting the compositor.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if command -v Hyprland >/dev/null; then
  if out=$(Hyprland --verify-config 2>&1); then
    log "Hyprland config OK"
  else
    warn "Hyprland reported config problems:"
    echo "$out" | grep -iE 'error|config' | head -20
  fi
fi

missing=()
for cmd in walker elephant satty waybar mako hyprlock hypridle swaybg swayosd-server uwsm xdg-terminal-exec alacritty tte; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if (( ${#missing[@]} )); then
  warn "Not on PATH yet (install packages / log in again): ${missing[*]}"
fi

# Hyprland auto-reloads when sourced files change, and the overlay step rewrites
# some of them twice (upstream restore, then overlay). A final reload clears any
# transient config error banner from that.
if [[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] && command -v hyprctl >/dev/null; then
  hyprctl reload >/dev/null 2>&1 || true
  if errs=$(hyprctl configerrors 2>/dev/null) && [[ -n $errs ]]; then
    warn "Hyprland still reports config errors:"
    echo "$errs"
  else
    log "Running Hyprland session reloaded cleanly"
  fi
fi
