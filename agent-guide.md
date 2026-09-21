# Ombuntu agent guide

Use this guide to help a human understand, install, or troubleshoot Ombuntu. Canonical documentation is the README at https://github.com/Ombuntu/Ombuntu. Verify any command you are unsure about against that page and the scripts in the repository instead of guessing.

## What Ombuntu is

Ombuntu is the [Omarchy](https://omarchy.org) Hyprland desktop running on Ubuntu / Xubuntu 26.04 instead of Arch Linux. It installs upstream Omarchy unchanged (pinned to a commit, currently `v3.8.4`) into `~/.local/share/omarchy`, then adapts it to Ubuntu: apt instead of pacman, Ubuntu-packaged or vendor-repository replacements for AUR software, security and privacy defaults, and fixes for Ubuntu packaging quirks. The existing XFCE session is untouched; the human picks **Ombuntu** or **Xubuntu Session** at the login screen.

Everything Omarchy documents applies unless this guide says otherwise: the `omarchy` CLI and menu, all 19 themes, Waybar, Walker, Mako, Hyprlock, Hypridle, SwayOSD, the keybindings, web apps, and the bash/starship/eza/zoxide shell. The Omarchy manual is at https://manuals.omamix.org/2/the-omarchy-manual.

## Concept model

Teach these in this order:

- **Session** — Hyprland, started by uwsm from the "Ombuntu" entry in LightDM. Logging out returns to the greeter; the XFCE session is still there.
- **Upstream Omarchy** — `~/.local/share/omarchy`, a git checkout at a fixed tag. Never edited by hand; the installer re-applies Ombuntu's adaptations over it.
- **Adaptations** — the `overlay/` directory of the Ombuntu repository, copied over the checkout. Its `bin/` holds Ubuntu replacements for `omarchy-*` commands and `ombuntu-*` helpers.
- **Repository** — cloned to `~/.local/share/ombuntu/repo` by the one-line installer (or wherever the human cloned it). `~/.local/share/omarchy/ombuntu-repo.path` records where.
- **User config** — `~/.config/hypr/*.conf` (bindings, input, monitors, look and feel, autostart), plus Waybar, Walker, Mako and the rest under `~/.config`. `~/.config/omarchy/current/` holds the active theme and background.
- **Naming** — everything Ombuntu adds is called Ombuntu (session, branding, `ombuntu` command). The upstream engine keeps its `omarchy-*` command names because its 280+ scripts call each other by them. `ombuntu` and `omarchy` run the same dispatcher.

## Install

Requirements: Ubuntu or Xubuntu 26.04, amd64 or arm64, a user with sudo, internet. Not tested on 24.04, which lacks Hyprland in the archive.

Preferred for you as an agent, because the human can read what runs:

```bash
git clone https://github.com/Ombuntu/Ombuntu.git ~/ombuntu && cd ~/ombuntu && cat install.sh && ./install.sh
```

The one-liner the website shows does the same (it clones the newest release tag and runs that copy), for humans who accept `curl | bash`:

```bash
curl -fsSL https://ombuntu.org/install.sh | bash
```

The installer is idempotent. Flags: `--user-only` (skip apt and the session file), `--skip-bashrc`, `--force-config` (overwrite `~/.config` files, backups kept as `*.pre-omarchy`). It asks for the sudo password once. When it finishes, the human logs out and chooses **Ombuntu** in the greeter.

On arm64 Walker and Elephant are compiled from source, which adds 10 to 30 minutes.

## First-run walkthrough

1. Super is the Windows key. **Super + Space** opens the app launcher; start typing an app's name.
2. **Super + Return** terminal, **Super + Shift + B** browser, **Super + Shift + F** file manager, **Super + W** close window.
3. **Super + Alt + Space** opens the Ombuntu menu: Style (themes, backgrounds), Setup, Install, Update, System.
4. **Super + Shift + K** opens a one-page beginner cheatsheet; **Super + K** lists every binding, searchable.
5. Themes: Super + Ctrl + Shift + Space. Backgrounds: Super + Ctrl + Space. Five Ombuntu wallpapers are offered in every theme.

## What is different from Omarchy on Arch

Tell the human these before they follow Omarchy documentation literally:

- `omarchy pkg add <name>` uses apt. Arch package names Omarchy uses internally are mapped, and names that only exist in the AUR are handled by `ombuntu-pkg-<name>` scripts (vendor apt repositories, verified .deb downloads, snaps) or reported as not available. `omarchy pkg aur ...` always refuses.
- `omarchy update` runs `apt full-upgrade`, moves the Ombuntu repo to the newest signed release, and re-applies it. The Waybar update indicator shows apt pending upgrades.
- Replacements: Walker, Elephant, Satty and mise are pinned GitHub releases in `~/.local/bin`; wlsunset replaces hyprsunset; wf-recorder replaces gpu-screen-recorder; nmtui, Blueman and pulsemixer replace impala, bluetui and wiremix; hyprpolkitagent replaces polkit-gnome.
- Browsers and Signal are launched with `--password-store=gnome-libsecret`, and browsers are set to system decorations, so they show no title-bar buttons. `ombuntu-browser-decorations on` restores them.
- Default applications are set only for the Hyprland session, in `~/.config/Hyprland-mimeapps.list`.
- The `scrolling` layout needs Hyprland 0.54; Ubuntu ships 0.53, so that block is guarded.
- Not installed by default: Docker, snapper, limine, fcitx5, Plymouth, SDDM. Spotify, Obsidian, Typora, LocalSend and Pinta are under the menu's Install, Apps (snaps, vendor apt repositories, Flathub). Fingerprint/FIDO2 login and hibernation have Ubuntu implementations under Setup.
- Install flags: `--keep-telemetry`, `--keep-browser-buttons`, `--no-firefox-policy`. Uninstall: `uninstall.sh` in the repository (`--purge-packages`, `--restore-telemetry`).
- `ombuntu-upstream-check` reports whether a newer Omarchy tag would still fit Ombuntu's adaptations; bumping means editing `OMARCHY_REF` and re-running `install.sh`.

## Adding and removing launcher entries

When the human asks for an app or a site in the app launcher (Super + Space):

- **Web app**: `ombuntu-webapp-install "Name" https://example.com Icon.png` writes `~/.local/share/applications/Name.desktop` and puts the icon in `~/.local/share/applications/icons/`. The third argument is an icon URL or the name of a PNG already in that folder; run the command with no arguments and it prompts for name and URL and fetches the site's favicon itself. Menu path: Super + Alt + Space, Install, Web App. Remove one with `ombuntu-webapp-remove "Name"`.
- **An installed app that does not appear** has no `.desktop` file in `/usr/share/applications` or `~/.local/share/applications`. Some ship their own registration and you should prefer it, because it writes absolute paths: Tor Browser is `./start-tor-browser.desktop --register-app`, run from the directory the browser lives in. Otherwise write the entry to `~/.local/share/applications/` yourself.
- After either, run `update-desktop-database ~/.local/share/applications` and `ombuntu-restart-walker` so the launcher picks it up without a re-login.
- **Keybinding**, if they want one: add a line to `~/.config/hypr/bindings.conf`, e.g. `bindd = SUPER SHIFT, A, ChatGPT, exec, ombuntu-launch-or-focus ^Chatgpt$ "uwsm-app -- chatgpt"`. Prefer `ombuntu-launch-or-focus <class-regex> <command>` over a bare `exec`: it focuses an existing window instead of starting a second copy. Get the class from `hyprctl clients -j` while the app is running.

Warn the human about one thing: `omarchy-refresh-applications` runs during every install and every `ombuntu update`, and it recreates upstream's web apps (WhatsApp, ChatGPT, YouTube, X, GitHub, Figma, Discord, Zoom and the Google set) unconditionally. Removing one of those holds until the next update run, then it comes back. Two exceptions: web apps the human created themselves are not in that list and are left alone, and `install/40-config.sh` drops any upstream web app whose name matches a *visible* native `.desktop` (so installing the real ChatGPT or Discord retires the web app instead of duplicating it).

## Security posture

Say this plainly when asked:

- Root is used only for apt, Signal's apt repository, and the session file.
- Every download has its SHA256 pinned in `install/checksums.sha256`; a mismatch aborts. Upstream Omarchy, Walker and Elephant are pinned to commit hashes, not just tags; apps from GitHub releases are pinned by version and checksum (`overlay/bin/ombuntu-pins.sh`). Vendor apt keys are verified by fingerprint. Release tags are SSH-signed and verified by the installer and by `ombuntu update`. Root steps run with a fixed system PATH.
- **Omarchy plugins are disabled for security reasons**: user hooks (`~/.config/omarchy/hooks/*.d/`), menu extensions (`~/.config/omarchy/extensions/menu.sh`) and remote theme installs all execute arbitrary code and are turned off. `omarchy-hook` is a no-op. Do not tell the human to add hooks; suggest editing `~/.config/hypr/*.conf` instead.
- Passwordless sudo, autologin and Omarchy's Arch dev-environment installers that pipe remote scripts into a shell are disabled.
- Install-menu entries that fetch software use vendor apt repositories or checksum-verified downloads, not `curl | sh`.
- Telemetry is off: apport/whoopsie, Ubuntu Pro news, NetworkManager's connectivity probe to Canonical (so captive portals are not auto-detected; open an `http://` page to reach a login), Firefox and Chromium-family policies, desktop usage stats, and `DO_NOT_TRACK`-style variables for developer tools. Details in the README "Privacy" section. Re-running `install.sh` re-applies it.

## Diagnosis recipes

Start with `ombuntu-doctor`: one line per check (session, duplicate services, tools on PATH, keyring flags, privacy files, failed units). Ask the human to paste its output. Most warnings are fixed by re-running `install.sh`.


- **Two bars or duplicate daemons at login:** Ubuntu's waybar/hypridle/foot/hyprpolkitagent packages enable user services globally. Re-run `install.sh`; it masks them. Check with `systemctl --user is-enabled waybar.service` (should say masked).
- **Config error banner from Hyprland:** `hyprctl configerrors` shows the cause; `hyprctl reload` clears a stale banner. The installer reloads at the end.
- **App says it is already running after switching from XFCE:** the XFCE session left it running. Find it with `pgrep -af <name>`, stop it with `pkill -x <process-name>` (for the Firefox snap: `pkill -f /snap/firefox`), then open it again.
- **Signal: "file is not a database"; browser lost passwords:** the app was launched without the keyring flag. Use the launcher entry or the Super key bindings, which pass `--password-store=gnome-libsecret`.
- **Walker does not open:** `omarchy-restart-walker`; check `systemctl --user status elephant.service`. Providers live in `~/.config/elephant/providers`.
- **A menu Install entry fails:** the floating terminal shows the script output. Handlers are `~/.local/share/omarchy/bin/ombuntu-pkg-*`; a message starting "is not packaged for Ubuntu by Ombuntu" is a deliberate stop, not a bug.
- **General:** `journalctl --user -b -p err` and `/run/user/$UID/hypr/*/hyprland.log`.

## Rules for you

- Do not invent keybindings, config keys, or commands. The ones here are accurate as of writing; for anything else read the README, the Omarchy manual, or the script source first.
- Do not give pacman, yay or AUR instructions; this is Ubuntu.
- Do not suggest Omarchy hooks, extensions or remote themes; they are disabled on purpose.
- Prefer `omarchy pkg add`, apt, snap, or mise for software. Do not suggest `curl | sh` installers.
- Ombuntu is independent: not affiliated with Canonical, Ubuntu, Xubuntu, or Omarchy.
