# Changelog

## 0.1.1

First signed release.

- Security review fixes: root steps run with a fixed PATH; upstream Omarchy, Walker and Elephant pinned to commits; a checkout is only trusted when it is your own git repository; vendor apt keys verified by fingerprint; Chrome and NordVPN from signed repositories; apt source lines fixed; manifest-based uninstall with `--dry-run`, removing only recorded packages; Ollama extracted root-owned; hibernation never unlinks live swap; Docker databases get random passwords.
- Screen-share restore tokens off; opening the Wi-Fi/Bluetooth panel no longer unblocks radios; Omarchy's bin last in PATH; FIDO2 requires the key's PIN; Firefox no longer forces video decoding past Mozilla's blocklist.
- Signed release tags, verified by the installer and by `ombuntu update`; GitHub-release apps pinned by version and SHA256 (`install/refresh-pins.sh`); GitHub Actions pinned to commit hashes.
- 1Password removed (Bitwarden stays). Vendor-matching apt source file names; snap browsers detected correctly; hibernation refuses Secure Boot lockdown.

## 0.1.0

First release. Omarchy v3.8.4 on Ubuntu / Xubuntu 26.04.

- One-line installer (`curl -fsSL https://ombuntu.org/install.sh | bash`), idempotent, amd64 and arm64.
- Ubuntu overlay: apt in place of pacman, vendor repositories and checksummed downloads in place of the AUR, Ubuntu stand-ins for hyprsunset, gpu-screen-recorder, impala, bluetui and wiremix.
- Fixes for Ubuntu packaging: duplicate waybar/hypridle services, dash-incompatible uwsm env, notification daemon clash, Hyprland 0.53 config guard.
- Keyring backend forced for browsers and Signal; browsers without title-bar buttons.
- Display scaling and keyboard layout detected at install.
- Privacy step: Canonical telemetry and connectivity probe, Firefox and Chromium-family data collection off; developer-tool opt-outs.
- Security: pinned checksums for every download; Omarchy hooks, menu extensions, remote themes, passwordless sudo and autologin disabled.
- Install menu trimmed to entries that work on Ubuntu; Apps submenu (Spotify, Obsidian, Typora, LocalSend, Pinta); Firefox from Mozilla's apt repository; fingerprint and FIDO2 login; hibernation on ext4.
- `ombuntu doctor`, `ombuntu-version`, `ombuntu-upstream-check`, `uninstall.sh`.
- Ombuntu branding, wallpapers, beginner cheatsheet, docs site, agent guide.
