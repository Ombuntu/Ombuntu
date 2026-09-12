#!/bin/bash
# Runs as root. Turns off telemetry and phone-home features added by Canonical
# and by browser vendors. Every change is a config file or a service state; the
# README "Privacy" section lists them and how to undo each one.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export DEBIAN_FRONTEND=noninteractive

# --- Canonical ---------------------------------------------------------------
# apport collects crash data locally and whoopsie uploads it to Canonical.
if [[ -f /etc/default/apport ]]; then
  sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport
fi
systemctl disable --now apport.service >/dev/null 2>&1 || true
apt-get purge -y whoopsie >/dev/null 2>&1 || true

# Never-used-here reporters, removed if present
apt-get purge -y ubuntu-report popularity-contest kerneloops >/dev/null 2>&1 || true

# Ubuntu Pro adverts in the message of the day and in apt output
if [[ -f /etc/default/motd-news ]]; then
  sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
fi
if command -v pro >/dev/null; then
  pro config set apt_news=false >/dev/null 2>&1 || true
fi
systemctl disable --now ua-timer.timer motd-news.timer >/dev/null 2>&1 || true

# NetworkManager's captive-portal probe to connectivity-check.ubuntu.com. Off means
# hotel/airport login pages are not detected automatically; open any http:// page to
# reach one. Delete the file below to restore the probe.
install -d -m 0755 /etc/NetworkManager/conf.d
cat >/etc/NetworkManager/conf.d/99-ombuntu-no-connectivity-check.conf <<'NM'
[connectivity]
enabled=false
NM
systemctl reload NetworkManager >/dev/null 2>&1 || true

# --- Firefox (deb or snap: both read /etc/firefox/policies) -----------------
if [[ $OMBUNTU_NO_FIREFOX_POLICY != true ]]; then
  install -d -m 0755 /etc/firefox/policies
  pol=/etc/firefox/policies/policies.json
  if [[ -s $pol ]] && ! grep -q '"_ombuntu"' "$pol"; then
    # A policy file we did not write (managed machine?) is kept, backed up, and not replaced
    warn "Existing $pol is not Ombuntu's; leaving it in place (saved copy: $pol.pre-ombuntu). Use --no-firefox-policy to silence this."
    cp -a "$pol" "$pol.pre-ombuntu"
  else
    install -m 0644 "$OMBUNTU_REPO/privacy/firefox-policies.json" "$pol"
  fi
fi

# --- Chromium family: Chrome, Chromium, Brave, Edge, Vivaldi ------------------
for dir in /etc/opt/chrome/policies/managed /etc/chromium/policies/managed /etc/brave/policies/managed /etc/opt/edge/policies/managed /etc/vivaldi/policies/managed; do
  install -d -m 0755 "$dir"
  install -m 0644 "$OMBUNTU_REPO/privacy/chromium-policies.json" "$dir/ombuntu-privacy.json"
done
install -m 0644 "$OMBUNTU_REPO/privacy/edge-policies.json" /etc/opt/edge/policies/managed/ombuntu-privacy-edge.json

log "Telemetry off: apport/whoopsie, Ubuntu Pro news, Firefox and Chromium-family policies"
