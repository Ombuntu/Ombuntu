#!/bin/bash
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ $(id -u) -ne 0 ]] || die "Run install.sh as your normal user, not root."
case "$OMBUNTU_ARCH" in
  amd64) ;;
  arm64) warn "arm64: Walker and Elephant have no prebuilt releases and will be compiled from source (10-30 minutes, needs ~2 GB of disk)." ;;
  *) die "Unsupported architecture: $OMBUNTU_ARCH (amd64 and arm64 are supported)." ;;
esac
source /etc/os-release
# Ubuntu 26.04 is the floor: earlier releases ship no Hyprland and are missing a
# third of packages.list, which otherwise only surfaces as a wall of apt errors.
if [[ $ID == ubuntu ]]; then
  [[ $(printf '%s\n' "${VERSION_ID:-0}" 26.04 | sort -V | head -1) == 26.04 ]] ||
    die "Ombuntu needs Ubuntu 26.04 or newer, found $PRETTY_NAME. Earlier releases do not ship Hyprland and many of the packages Ombuntu installs do not exist there."
elif [[ ${ID_LIKE:-} != *ubuntu* && ${ID_LIKE:-} != *debian* ]]; then
  warn "This was written for Ubuntu 26.04; package names may differ here."
fi
command -v git >/dev/null || die "git is required (sudo apt install git)."
command -v curl >/dev/null || die "curl is required (sudo apt install curl)."
log "OS: $PRETTY_NAME ($OMBUNTU_ARCH), user: $USER, Omarchy ref: $OMARCHY_REF"
