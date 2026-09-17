#!/bin/bash
# Runs as root. Chromium-family defaults: the extensions Ombuntu ships with and
# DuckDuckGo as the search engine. Separate from 70-privacy.sh on purpose, so
# --keep-telemetry does not also cost you the extensions.
#
# Extensions are "normal_installed": installed without a prompt, disableable by the
# user, not removable. Each id below, with the name it resolves to in the store:
#   pkehgijcmpdhfbdbbnkijodmdjhbjlgp  Privacy Badger (EFF)
#   eimadpbcbfnmbkopoojfekhnkhdbieeh  Dark Reader
#   aeblfdkhhhdcdjpifhhbdiojplfjncoa  1Password - Password Manager
#   nlipoenfbbikpbjkfpfillcgkoblgpmj  Awesome Screen Recorder & Screenshot
# Edit config-system/chromium-defaults.json to change the set.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# /etc/chromium-browser is where Ubuntu's chromium snap reads policy: its AppArmor profile
# allows /etc/chromium-browser/policies, not /etc/chromium/policies. Since chromium-browser
# is a transitional package to that snap, the snap is the Chromium most machines have.
for dir in /etc/opt/chrome/policies/managed /etc/chromium/policies/managed /etc/chromium-browser/policies/managed \
  /etc/brave/policies/managed /etc/opt/edge/policies/managed /etc/vivaldi/policies/managed; do
  install -d -m 0755 "$dir"
  install -m 0644 "$OMBUNTU_REPO/config-system/chromium-defaults.json" "$dir/ombuntu-defaults.json"
done

log "Chromium-family defaults: 4 extensions, DuckDuckGo search"
