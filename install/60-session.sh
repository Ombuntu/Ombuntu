#!/bin/bash
# Runs as root. Adds the "Omarchy" Wayland session for the LightDM greeter.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

rm -f /usr/share/wayland-sessions/omarchy.desktop
install -Dm644 "$OMBUNTU_REPO/config-system/ombuntu.desktop" /usr/share/wayland-sessions/ombuntu.desktop
log "Installed the Ombuntu login session"

install -Dm644 "$OMBUNTU_REPO/config-system/logind-power-key.conf" /etc/systemd/logind.conf.d/ombuntu-power-key.conf
systemctl reload systemd-logind 2>/dev/null || true # absent in containers; next boot applies it
log "Power key opens the power menu instead of powering off"
