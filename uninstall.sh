#!/bin/bash
#
# Ombuntu uninstaller. Removes the Ombuntu session, upstream Omarchy, and the
# files the installer wrote (tracked in ~/.local/state/ombuntu/manifest), and
# restores any *.pre-omarchy backups. Files you had before Ombuntu are kept.
#
# Usage:
#   ./uninstall.sh                     remove Ombuntu, keep apt packages and the privacy settings
#   ./uninstall.sh --dry-run           print what would be removed, change nothing
#   ./uninstall.sh --purge-packages    also apt-remove the packages the installer added
#   ./uninstall.sh --restore-telemetry also put Canonical/browser telemetry back to Ubuntu defaults
#   ./uninstall.sh --yes               do not ask for confirmation
#
set -eEo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PURGE=false; RESTORE=false; YES=false; DRY=false
for arg in "$@"; do
  case "$arg" in
  --purge-packages) PURGE=true ;;
  --restore-telemetry) RESTORE=true ;;
  --dry-run) DRY=true ;;
  --yes | -y) YES=true ;;
  -h | --help) sed -n '2,13p' "$0"; exit 0 ;;
  *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done
: "${HOME:?HOME must be set}"
MANIFEST="$HOME/.local/state/ombuntu/manifest"
log() { printf '\033[32m==>\033[0m %s\n' "$*"; }
run() { if [[ $DRY == true ]]; then printf '    would: %s\n' "$*"; else "$@"; fi; }

if [[ ${XDG_CURRENT_DESKTOP:-} == Hyprland && $DRY != true ]]; then
  echo "You are inside the Ombuntu session. Log out, choose Xubuntu Session, and run this from there." >&2
  exit 1
fi

# --- What will go: files from the manifest plus the directories only Ombuntu creates
mapfile -t manifest_files < <(grep -v '^\s*$' "$MANIFEST" 2>/dev/null || true)
ombuntu_dirs=(
  "$HOME/.local/share/omarchy" "$HOME/.local/share/ombuntu" "$HOME/.config/omarchy"
  "$HOME/.local/state/omarchy" "$HOME/.local/state/ombuntu" "$HOME/.cache/ombuntu"
  "$HOME/.local/share/applications/icons" "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
)
ombuntu_files=(
  "$HOME/.config/Hyprland-mimeapps.list" "$HOME/.config/hyprland-mimeapps.list"
  "$HOME/.config/autostart/walker.desktop" "$HOME/.config/autostart/polkit-mate-authentication-agent-1.desktop"
  "$HOME/.local/share/fonts/omarchy.ttf" "$HOME/.local/share/icons/hicolor/512x512/apps/ombuntu.png"
  "$HOME/.local/share/applications/ombuntu-cheatsheet.desktop"
  "$HOME/.config/systemd/user/elephant.service" "$HOME/.config/systemd/user/swayosd-server.service"
  "$HOME/.config/systemd/user/omarchy-battery-monitor.service" "$HOME/.config/systemd/user/omarchy-battery-monitor.timer"
  "$HOME/.config/systemd/user/omarchy-recover-internal-monitor.service"
)
for b in walker elephant satty mise omarchy ombuntu bat fd; do ombuntu_files+=("$HOME/.local/bin/$b"); done
for d in signal-desktop vivaldi-stable google-chrome brave-browser microsoft-edge chromium satty Alacritty imv mpv typora; do ombuntu_files+=("$HOME/.local/share/applications/$d.desktop"); done
for w in ChatGPT Discord Figma GitHub "Google Contacts" "Google Maps" "Google Messages" "Google Photos" WhatsApp X YouTube Zoom "Disk Usage" Docker; do ombuntu_files+=("$HOME/.local/share/applications/$w.desktop"); done
ombuntu_dirs+=("$HOME/.config/systemd/user/swayosd-server.service.d" "$HOME/.config/systemd/user/app-walker@autostart.service.d" "$HOME/.config/systemd/user/xfce4-notifyd.service.d")

echo "Ombuntu uninstall will remove:"
printf '  %d file(s) recorded in %s\n' "${#manifest_files[@]}" "$MANIFEST"
printf '  %s\n' "${ombuntu_dirs[@]}"
printf '  %d Ombuntu-generated file(s) under ~/.local and ~/.config\n' "${#ombuntu_files[@]}"
echo "  /usr/share/wayland-sessions/ombuntu.desktop"
[[ $PURGE == true ]] && echo "  apt packages listed in /etc/ombuntu/installed-packages ($( [[ -f /etc/ombuntu/installed-packages ]] && wc -l </etc/ombuntu/installed-packages || echo 0 ))"
[[ $RESTORE == true ]] && echo "  the privacy/telemetry changes (restored to Ubuntu defaults)"
echo "Kept: anything you had before Ombuntu, *.pre-omarchy backups are restored in place, ~/.local/share/mise."
[[ $DRY == true ]] && log "Dry run: nothing will be changed"
if [[ $YES != true && $DRY != true ]]; then
  read -r -p "Continue? [y/N] " a; [[ $a == y || $a == Y ]] || exit 0
fi

log "Root steps (sudo): login entry, policy files"
run sudo rm -f /usr/share/wayland-sessions/ombuntu.desktop
if [[ $RESTORE == true ]]; then
  log "Restoring Ubuntu telemetry defaults"
  [[ -f /etc/default/apport ]] && run sudo sed -i 's/^enabled=.*/enabled=1/' /etc/default/apport
  run sudo systemctl enable apport.service
  run sudo apt-get install -y whoopsie
  [[ -f /etc/default/motd-news ]] && run sudo sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/motd-news
  command -v pro >/dev/null && run sudo pro config set apt_news=true
  run sudo systemctl enable ua-timer.timer
  run sudo rm -f /etc/NetworkManager/conf.d/99-ombuntu-no-connectivity-check.conf
  run sudo systemctl reload NetworkManager
  # Only remove the Firefox policy if it is ours; restore a saved pre-existing one
  if grep -q '"_ombuntu"' /etc/firefox/policies/policies.json 2>/dev/null; then
    run sudo rm -f /etc/firefox/policies/policies.json
    [[ -f /etc/firefox/policies/policies.json.pre-ombuntu ]] && run sudo mv -f /etc/firefox/policies/policies.json.pre-ombuntu /etc/firefox/policies/policies.json
  fi
  run sudo rm -f /etc/opt/chrome/policies/managed/ombuntu-privacy.json /etc/chromium/policies/managed/ombuntu-privacy.json \
    /etc/brave/policies/managed/ombuntu-privacy.json /etc/opt/edge/policies/managed/ombuntu-privacy.json \
    /etc/opt/edge/policies/managed/ombuntu-privacy-edge.json /etc/vivaldi/policies/managed/ombuntu-privacy.json
  run sudo rm -f /etc/opt/chrome/policies/managed/ombuntu-defaults.json /etc/chromium/policies/managed/ombuntu-defaults.json \
    /etc/brave/policies/managed/ombuntu-defaults.json /etc/opt/edge/policies/managed/ombuntu-defaults.json \
    /etc/vivaldi/policies/managed/ombuntu-defaults.json
fi

log "User services"
run systemctl --user disable --now elephant.service swayosd-server.service omarchy-battery-monitor.timer 2>/dev/null || true
run systemctl --user unmask waybar.service hypridle.service foot-server.service foot-server.socket hyprpolkitagent.service \
  update-notifier-crash.path update-notifier-crash.service 2>/dev/null || true

log "Files the installer wrote (manifest)"
for f in "${manifest_files[@]}"; do
  [[ -e $f || -L $f ]] || continue
  run rm -f -- "$f"
  if [[ -e $f.pre-omarchy ]]; then run mv -f -- "$f.pre-omarchy" "$f"; fi
done
log "Ombuntu-generated files and directories"
for f in "${ombuntu_files[@]}"; do [[ -e $f || -L $f ]] && run rm -f -- "$f"; done
for d in "${ombuntu_dirs[@]}"; do [[ -d $d ]] && run rm -rf -- "$d"; done
# Directories Omarchy owns entirely: remove them only when nothing but our files was inside
for d in hypr waybar walker elephant mako swayosd alacritty uwsm fastfetch btop tmux lazygit imv opencode hyprland-preview-share-picker; do
  dir="$HOME/.config/$d"
  [[ -d $dir ]] || continue
  if [[ -z $(find "$dir" -type f -not -name '*.pre-omarchy' -print -quit 2>/dev/null) ]]; then
    run rm -rf -- "$dir"
  else
    echo "    kept $dir (contains files that are not Ombuntu's)"
  fi
done
run systemctl --user daemon-reload 2>/dev/null || true

for f in "$HOME/.bashrc" "$HOME/.config/git/config" "$HOME/.config/fontconfig/fonts.conf" "$HOME/.XCompose"; do
  if [[ -f $f.pre-omarchy ]]; then log "Restoring $f"; run mv -f -- "$f.pre-omarchy" "$f"; fi
done
run fc-cache -f >/dev/null 2>&1 || true
run update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

if [[ $PURGE == true ]]; then
  if [[ -s /etc/ombuntu/installed-packages ]]; then
    log "Removing the apt packages the installer added (from /etc/ombuntu/installed-packages)"
    mapfile -t pkgs </etc/ombuntu/installed-packages
    printf '    %s\n' "${pkgs[@]}"
    run sudo apt-get remove -y "${pkgs[@]}"
    run sudo apt-get autoremove -y
    run sudo rm -f /etc/apt/sources.list.d/signal-desktop.sources /usr/share/keyrings/signal-desktop-keyring.gpg /etc/ombuntu/installed-packages
  else
    echo "No record of installed packages (/etc/ombuntu/installed-packages); not removing any apt packages."
  fi
fi

log "Done. Log out and back in to clear the session environment."
