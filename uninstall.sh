#!/bin/bash
#
# Ombuntu uninstaller. Removes the Ombuntu session, upstream Omarchy, and the
# configuration Ombuntu wrote. XFCE is untouched by the install, so nothing there
# needs restoring.
#
# Usage:
#   ./uninstall.sh                     remove Ombuntu, keep apt packages and the privacy settings
#   ./uninstall.sh --purge-packages    also apt-remove the packages install/packages.list added
#   ./uninstall.sh --restore-telemetry also put Canonical/browser telemetry back to Ubuntu defaults
#   ./uninstall.sh --yes               do not ask for confirmation
#
set -eEo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PURGE=false; RESTORE=false; YES=false
for arg in "$@"; do
  case "$arg" in
  --purge-packages) PURGE=true ;;
  --restore-telemetry) RESTORE=true ;;
  --yes | -y) YES=true ;;
  -h | --help) sed -n '2,12p' "$0"; exit 0 ;;
  *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done
log() { printf '\033[32m==>\033[0m %s\n' "$*"; }

if [[ $XDG_CURRENT_DESKTOP == Hyprland ]]; then
  echo "You are inside the Ombuntu session. Log out, choose Xubuntu Session, and run this from there." >&2
  exit 1
fi
if [[ $YES != true ]]; then
  read -r -p "Remove Ombuntu from this machine? [y/N] " a; [[ $a == y || $a == Y ]] || exit 0
fi

log "Root steps (sudo): login entry, policy files"
sudo rm -f /usr/share/wayland-sessions/ombuntu.desktop
if [[ $RESTORE == true ]]; then
  log "Restoring Ubuntu telemetry defaults"
  [[ -f /etc/default/apport ]] && sudo sed -i 's/^enabled=.*/enabled=1/' /etc/default/apport
  sudo systemctl enable apport.service >/dev/null 2>&1 || true
  sudo apt-get install -y whoopsie >/dev/null 2>&1 || true
  [[ -f /etc/default/motd-news ]] && sudo sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/motd-news
  command -v pro >/dev/null && sudo pro config set apt_news=true >/dev/null 2>&1 || true
  sudo systemctl enable ua-timer.timer >/dev/null 2>&1 || true
  sudo rm -f /etc/firefox/policies/policies.json
  sudo rm -f /etc/opt/chrome/policies/managed/ombuntu-privacy.json /etc/chromium/policies/managed/ombuntu-privacy.json \
    /etc/brave/policies/managed/ombuntu-privacy.json /etc/opt/edge/policies/managed/ombuntu-privacy*.json /etc/vivaldi/policies/managed/ombuntu-privacy.json
fi

log "User services"
systemctl --user disable --now elephant.service swayosd-server.service omarchy-battery-monitor.timer >/dev/null 2>&1 || true
systemctl --user unmask waybar.service hypridle.service foot-server.service foot-server.socket hyprpolkitagent.service \
  update-notifier-crash.path update-notifier-crash.service >/dev/null 2>&1 || true
rm -f ~/.config/systemd/user/elephant.service ~/.config/systemd/user/swayosd-server.service \
  ~/.config/systemd/user/omarchy-battery-monitor.{service,timer} ~/.config/systemd/user/omarchy-recover-internal-monitor.service
rm -rf ~/.config/systemd/user/swayosd-server.service.d ~/.config/systemd/user/app-walker@autostart.service.d ~/.config/systemd/user/xfce4-notifyd.service.d
systemctl --user daemon-reload >/dev/null 2>&1 || true

log "Omarchy, Ombuntu data and configuration"
rm -rf ~/.local/share/omarchy ~/.local/share/ombuntu ~/.config/omarchy ~/.local/state/omarchy ~/.cache/ombuntu
rm -rf ~/.config/{hypr,waybar,walker,elephant,mako,swayosd,alacritty,uwsm,fastfetch,btop,tmux,lazygit,imv,opencode,hyprland-preview-share-picker}
rm -f ~/.config/starship.toml ~/.config/xdg-terminals.list ~/.config/Hyprland-mimeapps.list ~/.config/hyprland-mimeapps.list
rm -f ~/.config/autostart/walker.desktop ~/.config/autostart/polkit-mate-authentication-agent-1.desktop
rm -f ~/.local/bin/{walker,elephant,satty,mise,omarchy,ombuntu,bat,fd}
rm -f ~/.local/share/applications/{ombuntu-cheatsheet,signal-desktop,vivaldi-stable,google-chrome,brave-browser,microsoft-edge,chromium,satty,Alacritty,imv,mpv,typora}.desktop
rm -f ~/.local/share/applications/{ChatGPT,Discord,Figma,GitHub,"Google Contacts","Google Maps","Google Messages","Google Photos",WhatsApp,X,YouTube,Zoom,"Disk Usage",Docker}.desktop
rm -rf ~/.local/share/applications/icons ~/.local/share/fonts/JetBrainsMonoNerdFont ~/.local/share/fonts/omarchy.ttf
rm -f ~/.local/share/icons/hicolor/512x512/apps/ombuntu.png
rm -rf ~/.local/share/mise 2>/dev/null || true

if [[ -f ~/.bashrc.pre-omarchy ]]; then
  log "Restoring ~/.bashrc"
  mv -f ~/.bashrc.pre-omarchy ~/.bashrc
fi
for f in ~/.config/git/config ~/.config/fontconfig/fonts.conf ~/.XCompose; do
  [[ -f $f.pre-omarchy ]] && mv -f "$f.pre-omarchy" "$f"
done
# Files Ombuntu created from scratch (no backup means the user had none)
[[ -f ~/.config/git/config && ! -f ~/.config/git/config.pre-omarchy ]] && grep -q 'rerere' ~/.config/git/config && rm -f ~/.config/git/config
[[ -f ~/.config/fontconfig/fonts.conf ]] && grep -q 'JetBrainsMono Nerd Font' ~/.config/fontconfig/fonts.conf && rm -f ~/.config/fontconfig/fonts.conf
fc-cache -f >/dev/null 2>&1 || true
update-desktop-database ~/.local/share/applications >/dev/null 2>&1 || true

if [[ $PURGE == true ]]; then
  log "Removing apt packages from install/packages.list (Xubuntu's own packages are left alone)"
  mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$REPO/install/packages.list")
  sudo apt-get remove -y "${pkgs[@]}" signal-desktop 2>/dev/null || true
  sudo apt-get autoremove -y
  sudo rm -f /etc/apt/sources.list.d/signal-desktop.sources /usr/share/keyrings/signal-desktop-keyring.gpg
fi

log "Done. Log out and back in to clear the session environment."
