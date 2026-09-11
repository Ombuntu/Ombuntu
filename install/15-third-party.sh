#!/bin/bash
# Runs as root. Third-party apt repositories for apps Omarchy ships that Ubuntu
# does not package. Each block is idempotent.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export DEBIAN_FRONTEND=noninteractive

changed=false

# Signal Desktop (https://signal.org/download/linux/)
if [[ ! -s /usr/share/keyrings/signal-desktop-keyring.gpg ]]; then
  log "Adding Signal's apt signing key"
  curl -fsSL --retry 3 https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor >/usr/share/keyrings/signal-desktop-keyring.gpg
  changed=true
fi
if [[ ! -s /etc/apt/sources.list.d/signal-desktop.sources ]]; then
  log "Adding Signal's apt repository"
  curl -fsSL --retry 3 -o /etc/apt/sources.list.d/signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources
  changed=true
fi

[[ $changed == true ]] && apt-get update

dpkg-query -W -f='${Status}' signal-desktop 2>/dev/null | grep -q "install ok installed" || apt-get install -y signal-desktop
