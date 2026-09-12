# Changelog

## 0.1.0

First release. Omarchy v3.8.4 on Ubuntu / Xubuntu 26.04.

- One-line installer (`curl -fsSL https://ombuntu.org/install.sh | bash`), idempotent, amd64 and arm64.
- Ubuntu overlay: apt in place of pacman, vendor repositories and checksummed downloads in place of the AUR, Ubuntu stand-ins for hyprsunset, gpu-screen-recorder, impala, bluetui and wiremix.
- Fixes for Ubuntu packaging: duplicate waybar/hypridle services, dash-incompatible uwsm env, notification daemon clash, Hyprland 0.53 config guard.
- Keyring backend forced for browsers and Signal; browsers without title-bar buttons.
- Display scaling and keyboard layout detected at install.
- Privacy step: Canonical telemetry, Firefox and Chromium-family data collection off; developer-tool opt-outs.
- Security: pinned checksums for every download; Omarchy hooks, menu extensions, remote themes, passwordless sudo and autologin disabled.
- Install menu trimmed to entries that work on Ubuntu; Apps submenu (Spotify, Obsidian, Typora, 1Password, LocalSend, Pinta); Firefox from Mozilla's apt repository; fingerprint and FIDO2 login; hibernation on ext4.
- `ombuntu doctor`, `ombuntu-version`, `ombuntu-upstream-check`, `uninstall.sh`.
- Ombuntu branding, wallpapers, beginner cheatsheet, docs site, agent guide.
