#!/bin/bash
# Write ~/.config/Hyprland-mimeapps.list with Omarchy's default associations,
# using whichever Chromium-based browser is present (needed for web apps).
set -eEo pipefail

browser=""
for candidate in chromium.desktop chromium_chromium.desktop google-chrome.desktop brave-browser.desktop vivaldi-stable.desktop microsoft-edge.desktop; do
  if [[ -f /usr/share/applications/$candidate || -f ~/.local/share/applications/$candidate || -f /var/lib/snapd/desktop/applications/$candidate ]]; then
    browser=$candidate
    break
  fi
done
if [[ -z $browser ]]; then
  for candidate in firefox.desktop firefox_firefox.desktop; do
    [[ -f /usr/share/applications/$candidate || -f /var/lib/snapd/desktop/applications/$candidate ]] && browser=$candidate && break
  done
fi

{
  echo "[Default Applications]"
  [[ -n $browser ]] && printf '%s=%s\n' x-scheme-handler/http "$browser" x-scheme-handler/https "$browser" text/html "$browser"
  echo "inode/directory=org.gnome.Nautilus.desktop"
  for t in image/png image/jpeg image/gif image/webp image/bmp image/tiff; do echo "$t=imv.desktop"; done
  echo "application/pdf=org.gnome.Evince.desktop"
  for t in video/mp4 video/x-msvideo video/x-matroska video/x-flv video/x-ms-wmv video/mpeg video/ogg video/webm video/quicktime video/3gpp video/3gpp2 video/x-ms-asf video/x-ogm+ogg video/x-theora+ogg application/ogg; do echo "$t=mpv.desktop"; done
  for t in text/plain text/english text/x-makefile text/x-c++hdr text/x-c++src text/x-chdr text/x-csrc text/x-java text/x-moc text/x-pascal text/x-tcl text/x-tex application/x-shellscript text/x-c text/x-c++ application/xml text/xml; do echo "$t=nvim.desktop"; done
} >~/.config/Hyprland-mimeapps.list
ln -sfn Hyprland-mimeapps.list ~/.config/hyprland-mimeapps.list
