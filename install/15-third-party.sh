#!/bin/bash
# Runs as root. Third-party apt repositories for apps Omarchy ships that Ubuntu
# does not package. Each block is idempotent.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export DEBIAN_FRONTEND=noninteractive

changed=false

# Signal Desktop (https://signal.org/download/linux/). The signing key is fetched over TLS
# and then checked against the fingerprint Signal publishes; the sources file is ours.
SIGNAL_KEY_FPR="DBA36B5181D0C816F630E889D980A17457F6FB06"
if [[ ! -s /usr/share/keyrings/signal-desktop-keyring.gpg ]]; then
  log "Adding Signal's apt signing key"
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  curl -fsSL --retry 3 -o "$tmp/keys.asc" https://updates.signal.org/desktop/apt/keys.asc
  fpr=$(gpg --show-keys --with-colons "$tmp/keys.asc" 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}')
  [[ $fpr == "$SIGNAL_KEY_FPR" ]] || die "Signal apt key fingerprint is $fpr, expected $SIGNAL_KEY_FPR; not installing it"
  gpg --dearmor <"$tmp/keys.asc" >"$tmp/keyring.gpg"
  install -m 0644 "$tmp/keyring.gpg" /usr/share/keyrings/signal-desktop-keyring.gpg
  changed=true
fi
if [[ ! -s /etc/apt/sources.list.d/signal-desktop.sources ]]; then
  log "Adding Signal's apt repository"
  install -m 0644 "$OMBUNTU_REPO/config-system/signal-desktop.sources" /etc/apt/sources.list.d/signal-desktop.sources
  changed=true
fi

[[ $changed == true ]] && apt-get update

dpkg-query -W -f='${Status}' signal-desktop 2>/dev/null | grep -q "install ok installed" || apt-get install -y signal-desktop
