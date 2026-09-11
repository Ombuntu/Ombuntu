#!/bin/bash
# Apply the default Omarchy theme and the GNOME/GTK settings Omarchy expects.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

mkdir -p ~/.config/omarchy/themes ~/.config/btop/themes ~/.config/mako

if [[ ! -f ~/.config/omarchy/current/theme.name ]]; then
  OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy-theme-set tokyo-night >/dev/null 2>&1 || omarchy-theme-set tokyo-night
  # Pick the first background without needing a running compositor
  theme_bg_dir=~/.config/omarchy/current/theme/backgrounds
  first_bg=$(find -L "$theme_bg_dir" -maxdepth 1 -type f 2>/dev/null | sort | head -1)
  [[ -n $first_bg ]] && ln -nsf "$first_bg" ~/.config/omarchy/current/background
fi

ln -snf ~/.config/omarchy/current/theme/btop.theme ~/.config/btop/themes/current.theme
ln -snf ~/.config/omarchy/current/theme/mako.ini ~/.config/mako/config

# Omarchy's first-run GNOME theme settings (only affect GTK apps in the Hyprland session;
# XFCE's xsettings daemon overrides these under XFCE)
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "Yaru-blue" 2>/dev/null || true
