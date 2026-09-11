#!/bin/bash
# Runs as root. Installs the Ubuntu equivalents of Omarchy's base packages.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export DEBIAN_FRONTEND=noninteractive

mapfile -t packages < <(grep -vE '^\s*(#|$)' "$OMBUNTU_REPO/install/packages.list")

apt-get update
apt-get install -y --no-install-recommends "${packages[@]}"
# Recommends matter for a few desktop-facing packages (portals, blueman tray, qt styles)
apt-get install -y xdg-desktop-portal-hyprland xdg-desktop-portal-gtk blueman network-manager-gnome hyprpolkitagent

# Omarchy expects these command names
command -v bat >/dev/null 2>&1 || ln -sf /usr/bin/batcat /usr/local/bin/bat
command -v fd >/dev/null 2>&1 || ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Let the user manage power profiles and brightness like Omarchy expects
systemctl enable --now power-profiles-daemon.service >/dev/null 2>&1 || true
