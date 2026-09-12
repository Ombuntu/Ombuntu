# Ombuntu

**The [Omarchy](https://omarchy.org) Hyprland desktop on Xubuntu / Ubuntu 26.04.**

Ombuntu installs upstream Omarchy (pinned to tag `v3.8.4`) next to your
existing XFCE session and lays a small Ubuntu overlay on top of it. You get the
real thing: the `omarchy` CLI and menu, all 19 themes, Waybar, Walker, Mako,
Hyprlock, Hypridle, SwayOSD, the full keybinding set, web apps, and the
bash/starship/eza/zoxide shell. The overlay only swaps out what Arch has and
Ubuntu does not (package manager, a few tools, some paths) and works around a
couple of Ubuntu packaging quirks.

Nothing about XFCE is removed. You pick **Ombuntu** or **Xubuntu Session** in
the login screen.

## Requirements

| | Required |
| --- | --- |
| Distribution | Ubuntu 26.04 LTS or a flavour of it (built and tested on Xubuntu 26.04). Hyprland 0.53 comes from the Ubuntu archive; older releases do not ship it. |
| Architecture | amd64 (x86_64) or arm64 (aarch64), detected automatically. On amd64 every extra tool is a prebuilt release; on arm64 Walker and Elephant are compiled from source, which adds 10-30 minutes and a Rust/Go toolchain from apt. |
| Display manager | LightDM (Xubuntu default). GDM and SDDM also read `/usr/share/wayland-sessions`, but were not tested. |
| GPU | Anything with a Mesa Wayland driver: AMD, Intel, or Nvidia with the open kernel modules. Tested on AMD Radeon 890M. |
| Network | Internet access for apt and GitHub release downloads (about 250 MB) |
| Account | A user with sudo |
| Browser | Optional but recommended: a Chromium-based browser (Vivaldi, Chrome, Brave, Edge). Omarchy's "web apps" (ChatGPT, YouTube, WhatsApp and so on) open as app windows in it. Firefox is used only if none is present. |

Install from a fresh Xubuntu 26.04 or an existing one; the installer never
overwrites config files you already have unless you ask it to.

## Install

On a fresh Ubuntu or Xubuntu 26.04, one line does the whole install:

```bash
curl -fsSL https://ombuntu.org/install.sh | bash
```

It fetches this repository into `~/.local/share/ombuntu/repo`, asks for your
password once, installs everything, and adds the **Ombuntu** entry to the login
screen. Log out, pick Ombuntu, log in.

Prefer to read before you run? Download it first, or use a checkout:

```bash
git clone https://github.com/Ombuntu/Ombuntu.git ~/ombuntu
cd ~/ombuntu && ./install.sh
```

The installer:

1. Checks the OS and architecture.
2. Installs the Ubuntu packages (Hyprland, Waybar, Mako, Alacritty, Nautilus, the terminal tooling, fonts), then adds Signal's apt repository and installs Signal Desktop. These are the steps that need your password.
3. Clones Omarchy `v3.8.4` into `~/.local/share/omarchy` and applies the overlay.
4. Downloads pinned releases of Walker, Elephant, Satty and mise into `~/.local/bin`, plus the JetBrainsMono Nerd Font.
5. Writes the Omarchy configuration into `~/.config`, installs the bash setup (your old `~/.bashrc` is kept as `~/.bashrc.pre-omarchy`), and applies the Tokyo Night theme.
6. Adds the **Ombuntu** entry to the login screen.
7. Verifies the Hyprland config parses.

It is idempotent: run it again any time, it only redoes what is missing or
changed.

### Options

| Flag | Effect |
| --- | --- |
| `--user-only` | Skip the steps that need root (apt, session file) |
| `--skip-bashrc` | Leave `~/.bashrc` alone |
| `--force-config` | Overwrite `~/.config` files with Omarchy defaults (existing files saved as `*.pre-omarchy`) |

The piped form takes the same flags: `curl -fsSL https://ombuntu.org/install.sh | bash -s -- --skip-bashrc`.

Environment overrides: `OMARCHY_REF=v3.8.3 ./install.sh` pins another upstream
tag; `WALKER_VERSION`, `ELEPHANT_VERSION`, `SATTY_VERSION`, `MISE_VERSION`,
`NERD_FONTS_VERSION` do the same for the GitHub downloads.
`OMBUNTU_BUILD_FROM_SOURCE=true` compiles Walker and Elephant even on amd64.

### arm64

Ubuntu builds Hyprland and the rest of the desktop for arm64, so the apt side
is identical. Satty and mise publish aarch64 releases. Walker (Rust, GTK4) and
Elephant (Go) do not, so the installer adds the toolchains from
`install/packages-build.list` and compiles them at the pinned tags into
`~/.local/bin`. Expect the Walker build to take a while on a small board. The
Elephant build path is tested; the Walker build follows upstream's
`cargo build --release` and has not yet been run on real arm64 hardware, so
reports are welcome.

## First login

| Keys | Action |
| --- | --- |
| Super + Space | App launcher (Walker). `=` prefix calculates, `.` finds files, `:` emoji, `$` clipboard |
| Super + Alt + Space | Ombuntu menu: Style, Setup, Install, Update, System |
| Super + Return | Terminal (Alacritty) |
| Super + Shift + B | Browser |
| Super + Shift + F | File manager |
| Super + K | Searchable list of every keybinding |
| Super + W | Close window |
| Super + 1..0 | Workspaces |
| Super + Escape | Lock, suspend, logout, shutdown |
| Print | Screenshot (Satty editor on click) |

Change theme with Super + Ctrl + Shift + Space, background with Super + Ctrl + Space.
**Super + Shift + K** opens a one-page beginner cheatsheet (also "Ombuntu
Cheatsheet" in the app launcher, and `docs/cheatsheet.html` in this repo).
The full manual is at <https://manuals.omamix.org/2/the-omarchy-manual>.

## What is different from Omarchy on Arch

| Omarchy (Arch) | Ombuntu (Ubuntu 26.04) | Why |
| --- | --- | --- |
| `pacman`/`yay` via `omarchy-pkg-*` | `apt` via the same `omarchy-pkg-*` commands | No AUR; `omarchy pkg aur ...` says so |
| `omarchy-update` (git + pacman) | `apt full-upgrade` + re-apply this overlay | Upstream is pinned to a tag |
| Waybar update dot | apt pending-upgrade count | |
| Walker / Elephant (AUR) | Prebuilt GitHub releases in `~/.local/bin` | Not packaged by Ubuntu |
| Satty, mise (AUR) | Prebuilt GitHub releases | Not packaged by Ubuntu |
| gpu-screen-recorder | `wf-recorder` (no webcam overlay, one audio source) | Not packaged by Ubuntu |
| hyprsunset (nightlight) | `wlsunset` | Not packaged by Ubuntu |
| impala (Wi-Fi TUI) | `nmtui` (NetworkManager) | Xubuntu uses NetworkManager, not iwd |
| bluetui | Blueman | Not packaged by Ubuntu |
| wiremix (audio TUI) | `pulsemixer` | Not packaged by Ubuntu |
| polkit-gnome | hyprpolkitagent (MATE/GNOME/KDE agents as fallback) | Path differs on Ubuntu |
| fcitx5 input method | Not installed | Avoids fighting Xubuntu's ibus setup; `~/.XCompose` still works |
| Chromium | Whichever Chromium-based browser is installed | Ubuntu's Chromium is a snap |
| SDDM + Plymouth | LightDM (untouched) | Only a Wayland session entry is added |
| Compositor starts waybar/hypridle | Same, and the Ubuntu packages' user services are masked | The debs enable `waybar.service` and `hypridle.service` globally, which produced a second bar |
| `~/.config/uwsm/env` in bash | POSIX sh version | uwsm runs it with `/bin/sh` (dash on Ubuntu) |
| Mako only | Mako, with XFCE's `xfce4-notifyd` kept out of the Hyprland session | Both claim the notifications bus name |
| `scrolling` layout option | Guarded with `hyprlang noerror` | Needs Hyprland 0.54+, Ubuntu has 0.53.3 |
| Default apps set globally | Set only for the Hyprland session (`~/.config/Hyprland-mimeapps.list`) | Keeps XFCE defaults intact |
| Hooks, menu extensions, remote theme install | Disabled | Security: they execute arbitrary user-supplied code |
| Install menu (editors, browsers, AI, gaming, services) | Vendor apt repositories, checksum-verified downloads, snaps, or "not available" | No AUR; no `curl \| sh` |
| Browser title-bar buttons | Chromium-family browsers and Firefox switched to system decorations, so no minimize/maximize/close buttons | Hyprland draws no decorations; `ombuntu-browser-decorations on` restores them |

Signal Desktop is installed from Signal's own apt repository, as on Arch.

**Omarchy plugins are disabled for security reasons.** Omarchy's hooks
(`~/.config/omarchy/hooks/*.d/`), menu extensions
(`~/.config/omarchy/extensions/menu.sh`) and remote theme installs all run
arbitrary code with your user rights, triggered by everyday actions such as
booting, changing theme or updating. Ombuntu turns these off; see
[Security notes](#security-notes) for the full list.

Skipped entirely: 1Password, Spotify, Obsidian, Typora, LocalSend, Pinta,
Docker, snapper/limine, the Arch hardware fix-ups, and the HEY, Basecamp and
Fizzy web apps and bindings. Their keybindings stay in
`~/.config/hypr/bindings.conf` so you can point them at snaps or debs if you
install them.

### Wallpapers

Five Ombuntu wallpapers ship in `backgrounds/` at 3840x2400 (16:10, suits 4K
and 5K displays; Hyprland scales them to fit). They are offered in every theme
(Super + Ctrl + Space cycles backgrounds, or Style, Background in the menu)
ahead of the theme's own images, and the horizon one is the default on a fresh
install. Drop more images in `~/.config/omarchy/backgrounds/<theme>/` to add
your own.

### Naming

Everything this repo adds is called Ombuntu: the login session, the About
screen and screensaver, the `ombuntu` command. The upstream engine keeps its
`omarchy-*` command names and `~/.local/share/omarchy` path, because its 280+
scripts call each other by those names. `ombuntu` is the same dispatcher, so
`ombuntu theme set nord` and `omarchy theme set nord` are equivalent.

## Updating

`ombuntu update` (or the menu: Update, Omarchy) runs `apt full-upgrade`, pulls
this repo, and re-applies the overlay. Running the one-line installer again
does the same. To move to a newer upstream Omarchy,
change `OMARCHY_REF` in `install.sh`, run it, and check that the files in
`overlay/` still make sense against the new upstream.

## Troubleshooting

**Two bars, or two error popups at login.** Run `./install.sh` again. Ubuntu's
waybar, hypridle and foot packages enable systemd user services that duplicate
what Omarchy starts; the installer masks them.

**"Firefox is already running" (or any app) after switching from XFCE.** The
XFCE session left the app running. `pkill -f /snap/firefox` and open it again.
Rebooting between desktops avoids this.

**Config error banner from Hyprland.** `hyprctl configerrors` shows the cause.
A banner right after running the installer is transient; `hyprctl reload`
clears it (the installer does this itself at the end).

**Signal says "file is not a database", or the browser lost its saved
passwords.** Chromium and Electron apps only use the GNOME keyring on desktops
they recognise; under Hyprland they fall back to plain-text storage and cannot
decrypt what was saved under XFCE. Ombuntu launches Signal, Vivaldi, Chrome,
Brave, Edge and Chromium with `--password-store=gnome-libsecret` (launcher
entries, web apps, Super+Shift+B and Super+Shift+G). Passwords saved while the
flag was missing are the only ones not recovered. If you start a browser some
other way, add that flag.

**Walker does not open.** `omarchy-restart-walker`, or check
`systemctl --user status elephant.service`. Elephant's providers live in
`~/.config/elephant/providers`.

**Something in the Hyprland session is off.** `journalctl --user -b -p err` and
the Hyprland log under `/run/user/$UID/hypr/*/hyprland.log` are the places to
look. Include their output if you open an issue.

## Security notes

What the installer does with privilege, and what it deliberately leaves out.

- **Root is used for three things only:** apt packages, Signal's apt key and
  repository (fetched over HTTPS from signal.org), and one session file under
  `/usr/share/wayland-sessions`. Everything else lives in your home directory.
- **Every download is pinned and checksummed.** `install/checksums.sha256`
  holds the SHA256 of each Walker, Elephant, Satty, mise and Nerd Font archive;
  a mismatch aborts the install. Upstream Omarchy is cloned at a fixed tag.
- **No plugin or hook execution.** Omarchy runs user scripts from
  `~/.config/omarchy/hooks/*.d/` on boot, theme change and update, and sources
  `~/.config/omarchy/extensions/menu.sh` into its menu. Ombuntu disables both:
  `omarchy-hook` is a no-op, `omarchy-hook-install` refuses, the menu no longer
  sources extensions, and the sample hook directories are not installed.
- **No remote theme installs.** `omarchy-theme-install` (git clone of an
  arbitrary repository, whose `neovim.lua` and templates are executed) is
  disabled. The 19 bundled themes are available; copy a reviewed theme into
  `~/.config/omarchy/themes/` by hand if you want another.
- **No privilege shortcuts.** Omarchy's menu offers passwordless sudo and
  autologin ("direct boot"); both are disabled here. Its Arch-only
  dev-environment installers, which pipe remote scripts into a shell, are
  disabled too; use apt or mise.
- **Keyring, not plain text.** Browsers and Signal are launched with the GNOME
  keyring backend, so saved passwords are encrypted with your login keyring
  rather than a fixed key on disk.
- **Screen lock** after 5 minutes idle via Hyprlock and PAM; a screensaver runs
  at 2.5 minutes. `ombuntu toggle idle` turns it off for the session.
- **Firewall.** Ubuntu's `ufw` is left as you have it (enabled by default on a
  Xubuntu install). Omarchy would additionally open its LocalSend port; Ombuntu
  does not install LocalSend, so nothing is opened.

Things to be aware of that are inherited from Omarchy's design: the clipboard
manager keeps a history of what you copy (Super + Ctrl + V; clear it from the
same menu), the launcher's web search sends what you type to the configured
search engine when you use the `@` prefix, and screen sharing remembers your
choice of screen (`allow_token_by_default` in `~/.config/hypr/xdph.conf`) so
that apps do not prompt every time. Set that to `false` if you prefer a prompt.

## Privacy

Ubuntu and the browsers phone home by default. The installer's privacy step
turns that off; each item is a config file or service state you can reverse.

- **Canonical:** apport crash collection disabled and the whoopsie uploader
  removed; ubuntu-report, popularity-contest and kerneloops removed if present;
  Ubuntu Pro adverts off in the login message (`/etc/default/motd-news`) and in
  apt (`pro config set apt_news=false`), and the Pro timer disabled. The desktop
  privacy settings for usage statistics and problem reports are off.
- **Firefox:** telemetry, studies, Pocket, sponsored tiles and suggestions off
  via `/etc/firefox/policies/policies.json` (the snap reads it too). Tracking
  protection is set to strict.
- **Chrome, Chromium, Brave, Edge, Vivaldi:** metrics reporting, URL-keyed data
  collection, extended Safe Browsing reporting, the Google spell-check service,
  search suggestions, alternate error pages, link prefetching, promotions,
  surveys and the Privacy Sandbox ad APIs off via a policy file in each
  browser's `/etc/.../policies/managed` directory. Vivaldi additionally sends
  its own anonymous usage-count ping, which has no policy switch.
- **Developer tools:** `DO_NOT_TRACK=1` and the opt-out variables for .NET,
  Next.js, Nuxt, Astro, Gatsby, Homebrew, PowerShell, Azure CLI, AWS SAM,
  Stripe CLI and Hugging Face are set in the session and shell. VS Code and Zed
  installed from the menu get telemetry off in their settings.

Left alone, and why: snapd talks to the Snap Store to keep Firefox updated
(inherent to snaps); NetworkManager's captive-portal check contacts
`connectivity-check.ubuntu.com` when a network comes up, which is what makes
hotel Wi-Fi login pages appear (disable with a `[connectivity] enabled=false`
NetworkManager config if you prefer); apt itself downloads package lists from
Ubuntu mirrors. Signal, Walker, Elephant, Mako, Waybar and the rest of the
desktop have no telemetry.

## Uninstall

XFCE is untouched, so removal is:

```bash
sudo rm /usr/share/wayland-sessions/ombuntu.desktop
rm -rf ~/.local/share/omarchy ~/.config/omarchy ~/.local/state/omarchy
rm -rf ~/.config/{hypr,waybar,walker,elephant,mako,swayosd,alacritty,uwsm}
rm ~/.local/bin/{walker,elephant,satty,mise,omarchy,ombuntu}
mv ~/.bashrc.pre-omarchy ~/.bashrc
systemctl --user unmask waybar.service hypridle.service foot-server.service foot-server.socket hyprpolkitagent.service
```

Then `sudo apt remove` whichever packages from `install/packages.list` you do
not want. Other Omarchy files under `~/.config` (btop, fastfetch, starship,
tmux, git, fontconfig) are harmless to keep or delete.

## Files this touches

- `~/.local/share/omarchy` (upstream clone + overlay)
- `~/.config/hypr/*`, `waybar`, `walker`, `elephant`, `mako`, `swayosd`, `alacritty`, `btop`, `fastfetch`, `starship.toml`, `tmux`, `git/config`, `fontconfig/fonts.conf`, `uwsm`, `xdg-terminals.list`, `omarchy/*`, `Hyprland-mimeapps.list`, `autostart/*.desktop`, `systemd/user/*`
- `~/.bashrc` (backup kept), `~/.XCompose`, `~/.local/bin/*`, `~/.local/share/fonts`, `~/.local/share/applications`
- `/usr/share/wayland-sessions/ombuntu.desktop`

`~/.config/git/config`, `~/.bashrc` and `~/.config/fontconfig/fonts.conf` also
apply inside XFCE, because Omarchy treats the shell and fonts as part of the
experience. Use `--skip-bashrc` or delete those files if you prefer the Ubuntu
defaults there.

## Repository layout

```
install.sh            entry point
install/              one script per step, packages.list and packages-build.list (apt), lib.sh
overlay/              files copied over the upstream Omarchy clone
  bin/                Ubuntu replacements for omarchy-* commands
  default/            autostart, app rules, waybar indicator, bash init, looknfeel/foot fixes
  config/hypr/        1x monitor default for a 1080p laptop panel
config/               extra ~/.config files (elephant.service, POSIX uwsm env)
config-system/        the Wayland session entry installed to /usr/share
branding/             Ombuntu ASCII art for the About screen and screensaver
docs/                 beginner keyboard cheatsheet (HTML)
backgrounds/          Ombuntu wallpapers, linked into every theme
```

## For AI agents

`agent-guide.md` (served at https://ombuntu.org/agent-guide.md) teaches a
coding agent to install, explain and troubleshoot Ombuntu for a human: the
concept model, what differs from Omarchy on Arch, the security posture, and
diagnosis recipes. Point your agent at it.

## Hosting install.sh at ombuntu.org

`ombuntu.org/install.sh` is this repository's root served by GitHub Pages:
`CNAME` names the domain, `.nojekyll` keeps files verbatim, and `index.html`
is the landing page. In the repository settings enable Pages from the `main`
branch, root folder, and point the domain's DNS at GitHub Pages. Until then
the same file is reachable at
`https://raw.githubusercontent.com/Ombuntu/Ombuntu/main/install.sh`.

## Credits and license

Omarchy is by DHH and contributors, MIT licensed. Ombuntu is MIT as well; the
scripts under `overlay/bin` are adapted from Omarchy's.

## Disclaimer

Ombuntu is an independent community project. It is not affiliated with,
endorsed by, or associated with Canonical Ltd., Ubuntu, Xubuntu, or the Omarchy
project. Ubuntu and Xubuntu are trademarks of Canonical Ltd. Omarchy is a
project of DHH and contributors. Use at your own risk.
