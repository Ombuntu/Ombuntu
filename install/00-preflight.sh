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
[[ $ID == ubuntu || ${ID_LIKE:-} == *ubuntu* || ${ID_LIKE:-} == *debian* ]] || warn "This was written for Ubuntu 26.04; package names may differ here."
command -v git >/dev/null || die "git is required (sudo apt install git)."
command -v curl >/dev/null || die "curl is required (sudo apt install curl)."
log "OS: $PRETTY_NAME ($OMBUNTU_ARCH), user: $USER, Omarchy ref: $OMARCHY_REF"
