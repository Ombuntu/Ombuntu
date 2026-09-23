# Changelog

## 0.1.3

- Screen sharing works: `xdph.conf` named Omarchy's `hyprland-preview-share-picker`, which exists only in Arch's hyprland-qtutils, so the portal launched a missing binary and every request came back to the application as "cancelled by user" - in OBS, Zoom, Teams and Discord alike. Unset, xdph uses the `hyprland-share-picker` Ubuntu packages.
- The Waybar tray is no longer empty: Xubuntu's Ayatana indicator service starts in any session and takes `org.kde.StatusNotifierWatcher`, so after an XFCE login every tray item registered with it instead of Waybar. It is now hidden under Hyprland, like the MATE polkit agent.
- Web apps: `omarchy-launch-webapp` fell back to `chromium.desktop`, a name Ubuntu has never shipped (the snap is `chromium_chromium.desktop`, the deb `chromium-browser.desktop`), so with snap Chromium as the default browser every web app binding died with "Command not found". Upstream web apps whose real application is installed are now retired instead of listed twice.
- Every Omarchy tool is also an `ombuntu-*` command, `ombuntu <Tab>` completes subcommands, and the dispatcher names the desktop it drives. Upstream keeps its own names, so the checkout stays byte-identical to its pinned commit.
- Chromium-family defaults, in their own step so `--keep-telemetry` no longer costs you them: Privacy Badger, Dark Reader, 1Password and Awesome Screen Recorder, with DuckDuckGo as the search engine. The privacy policy is also written to `/etc/chromium-browser/policies`, the path Ubuntu's Chromium snap actually reads - it never applied there before.
- `systemd-oomd` is installed and enabled, `--no-oomd` skips it. Xubuntu ships no userspace OOM handler, so a runaway application thrashes the machine into swap and freezes the desktop long before the kernel steps in.
- The Learn menu opens Ombuntu's documentation rather than the Omarchy manual, and `--help` prints the help instead of the whole script.
- The agent guide, the FAQ and the command table document how to add and remove launcher entries and web apps.

## 0.1.2

- The installer refuses Ubuntu releases older than 26.04, in preflight and in the one-line bootstrap, instead of reaching apt and failing with a wall of `Unable to locate package`; the package step also reports apt failures in its own words.
- The package step no longer fails on a non-C locale: `comm` compares byte-wise while `sort` followed the caller's collation, so the step reported failure after installing everything correctly and the install stopped with no error of its own. Package bookkeeping can no longer abort an install.
- `plocate` dropped: nothing in Ombuntu or Omarchy calls `locate`, and its first-run `updatedb` looks exactly like a hung installer on a machine with large or slow mounts.
- The background chooser offers only Ombuntu wallpapers, and the theme step no longer looks in the removed theme background folder on a fresh install.
- Wording throughout: Ombuntu's adaptations, not an Omarchy overlay. The landing page opens the cheatsheet in a new tab.

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
