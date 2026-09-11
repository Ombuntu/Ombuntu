#!/bin/bash
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ $(id -u) -ne 0 ]] || die "Run install.sh as your normal user, not root."
[[ $(uname -m) == x86_64 ]] || die "Only x86_64 is supported (prebuilt Walker/Elephant/Satty binaries)."
source /etc/os-release
[[ $ID == ubuntu || ${ID_LIKE:-} == *ubuntu* || ${ID_LIKE:-} == *debian* ]] || warn "This was written for Ubuntu 26.04; package names may differ here."
command -v git >/dev/null || die "git is required (sudo apt install git)."
command -v curl >/dev/null || die "curl is required (sudo apt install curl)."
log "OS: $PRETTY_NAME, user: $USER, Omarchy ref: $OMARCHY_REF"
