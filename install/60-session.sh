#!/bin/bash
# Runs as root. Adds the "Omarchy" Wayland session for the LightDM greeter.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

rm -f /usr/share/wayland-sessions/omarchy.desktop
install -Dm644 "$OMBUNTU_REPO/config-system/ombuntu.desktop" /usr/share/wayland-sessions/ombuntu.desktop
log "Installed the Ombuntu login session"
