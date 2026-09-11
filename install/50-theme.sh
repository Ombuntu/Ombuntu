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

# Ombuntu wallpapers: offered in every theme (Omarchy lists user backgrounds under
# ~/.config/omarchy/backgrounds/<theme>/ ahead of the theme's own), and the first
# one is the default background on a fresh install.
BG_STORE=~/.local/share/ombuntu/backgrounds
mkdir -p "$BG_STORE"
cp -f "$OMBUNTU_REPO"/backgrounds/*.png "$BG_STORE/"
for theme_dir in "$OMARCHY_PATH"/themes/* ~/.config/omarchy/themes/*; do
  [[ -d $theme_dir ]] || continue
  theme=$(basename "$theme_dir")
  mkdir -p ~/.config/omarchy/backgrounds/"$theme"
  for bg in "$BG_STORE"/*.png; do
    ln -sfn "$bg" ~/.config/omarchy/backgrounds/"$theme"/"$(basename "$bg")"
  done
done

# Use the Ombuntu default wallpaper unless the user already picked their own
current_bg=$(readlink ~/.config/omarchy/current/background 2>/dev/null || true)
if [[ -z $current_bg || $current_bg == "$HOME/.config/omarchy/current/theme/backgrounds/"* ]]; then
  omarchy-theme-bg-set "$(ls "$BG_STORE"/*.png | sort | head -1)" >/dev/null 2>&1 ||
    ln -nsf "$(ls "$BG_STORE"/*.png | sort | head -1)" ~/.config/omarchy/current/background
fi
