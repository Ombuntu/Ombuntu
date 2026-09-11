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

```bash
sudo apt install -y git curl
git clone https://github.com/Ombuntu/Ombuntu.git ~/ombuntu
cd ~/ombuntu
./install.sh
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

Then log out, choose **Ombuntu** in the greeter (the small icon next to your
name in LightDM), and log in.

### Options

| Flag | Effect |
| --- | --- |
| `--user-only` | Skip the steps that need root (apt, session file) |
| `--skip-bashrc` | Leave `~/.bashrc` alone |
| `--force-config` | Overwrite `~/.config` files with Omarchy defaults (existing files saved as `*.pre-omarchy`) |

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

Signal Desktop is installed from Signal's own apt repository, as on Arch.

Skipped entirely: 1Password, Spotify, Obsidian, Typora, LocalSend, Pinta,
Docker, snapper/limine, and the Arch hardware fix-ups. Their keybindings stay in
`~/.config/hypr/bindings.conf` so you can point them at snaps or debs if you
install them.

### Wallpapers

Five Ombuntu wallpapers ship in `backgrounds/`. They are offered in every theme
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
this repo, and re-applies the overlay. To move to a newer upstream Omarchy,
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

**Signal says "file is not a database" and quits.** Electron apps only use the
GNOME keyring on desktops they recognise; under Hyprland they fall back to
plain-text storage and cannot decrypt a database created under XFCE. Ombuntu
launches Signal with `--password-store=gnome-libsecret` (launcher entry and
Super+Shift+G). If you start it another way, add that flag.

**Walker does not open.** `omarchy-restart-walker`, or check
`systemctl --user status elephant.service`. Elephant's providers live in
`~/.config/elephant/providers`.

**Something in the Hyprland session is off.** `journalctl --user -b -p err` and
the Hyprland log under `/run/user/$UID/hypr/*/hyprland.log` are the places to
look. Include their output if you open an issue.

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
backgrounds/          Ombuntu wallpapers, linked into every theme
```

## Credits and license

Omarchy is by DHH and contributors, MIT licensed. Ombuntu is MIT as well; the
scripts under `overlay/bin` are adapted from Omarchy's.
