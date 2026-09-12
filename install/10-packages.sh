#!/bin/bash
# Runs as root. Installs the Ubuntu equivalents of Omarchy's base packages.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export DEBIAN_FRONTEND=noninteractive

mapfile -t packages < <(grep -vE '^\s*(#|$)' "$OMBUNTU_REPO/install/packages.list")

# Remember which packages this run adds, so uninstall.sh removes only those (never
# packages that were already part of the system).
before=$(mktemp); dpkg-query -W -f='${binary:Package}\n' 2>/dev/null | sort >"$before"
mkdir -p /etc/ombuntu
record_new_packages() {
  dpkg-query -W -f='${binary:Package}\n' 2>/dev/null | sort | comm -13 "$before" - >>/etc/ombuntu/installed-packages
  sort -u -o /etc/ombuntu/installed-packages /etc/ombuntu/installed-packages
  rm -f "$before"
}
trap record_new_packages EXIT

apt-get update
apt-get install -y --no-install-recommends "${packages[@]}" ||
  die "apt could not install every package in install/packages.list (see the errors above). Ombuntu is built for Ubuntu 26.04 or newer."
# Recommends matter for a few desktop-facing packages (portals, blueman tray, qt styles)
apt-get install -y xdg-desktop-portal-hyprland xdg-desktop-portal-gtk blueman network-manager-gnome hyprpolkitagent

# Toolchains for building Walker (Rust/GTK4) and Elephant (Go) where no prebuilt release exists
if [[ $OMBUNTU_ARCH != amd64 || $OMBUNTU_BUILD_FROM_SOURCE == true ]]; then
  mapfile -t build_packages < <(grep -vE '^\s*(#|$)' "$OMBUNTU_REPO/install/packages-build.list")
  apt-get install -y --no-install-recommends "${build_packages[@]}"
fi

# Sanity check: the tools later steps rely on must exist now (a package can be "installed"
# in a minimised image yet lack its binary); reinstall the owner if one is missing.
declare -A tool_pkg=([xz]=xz-utils [zstd]=zstd [gpg]=gnupg [python3]=python3 [fc-cache]=fontconfig [tar]=tar [curl]=curl [git]=git [jq]=jq [unzip]=unzip)
for tool in "${!tool_pkg[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "==> $tool missing after install; reinstalling ${tool_pkg[$tool]}"
    apt-get install -y --reinstall "${tool_pkg[$tool]}"
    command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: $tool still missing" >&2; exit 1; }
  fi
done

# Omarchy expects these command names
command -v bat >/dev/null 2>&1 || ln -sf /usr/bin/batcat /usr/local/bin/bat
command -v fd >/dev/null 2>&1 || ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Let the user manage power profiles and brightness like Omarchy expects
systemctl enable --now power-profiles-daemon.service >/dev/null 2>&1 || true
