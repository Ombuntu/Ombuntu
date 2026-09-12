#!/usr/bin/env python3
"""Trim Omarchy's menu (bin/omarchy-menu) to what works on Ubuntu.

Applied by install/30-omarchy.sh after the overlay is copied. Menu entries are
"<glyph>  Label" items joined by literal \\n inside quoted strings; edits match on
the label so upstream icon changes do not break them. Each edit asserts that it
matched, so an upstream restructure fails loudly instead of leaving Arch-only
entries behind.
"""
import re, sys

path = sys.argv[1]
s = open(path, encoding="utf-8").read()
orig = s

def drop_option(label):
    """Remove a '<glyph>  Label' item from every option string it appears in."""
    global s
    lab = re.escape(label)
    new = re.sub(r'\\n\S  ' + lab + r'(?=\\n|")', '', s)          # middle or last item
    new = re.sub(r'(?<=")\S  ' + lab + r'\\n', '', new)            # first item
    assert new != s, f"menu patch: option {label!r} not found"
    s = new

def drop_option_in(menu_title, label):
    """Remove a '<glyph>  Label' item only from the option string of one menu."""
    global s
    lab = re.escape(label)
    def fix(m):
        line = m.group(0)
        out = re.sub(r'\\n\S  ' + lab + r'(?=\\n|")', '', line)
        out = re.sub(r'(?<=")\S  ' + lab + r'\\n', '', out)
        assert out != line, f"menu patch: option {label!r} not in menu {menu_title!r}"
        return out
    new = re.sub(r'^.*menu "' + re.escape(menu_title) + r'" ".*$', fix, s, count=1, flags=re.M)
    assert new != s, f"menu patch: menu {menu_title!r} not found"
    s = new

def drop_line(pattern):
    global s
    new = re.sub(r"^.*" + pattern + r".*\n", "", s, flags=re.M)
    assert new != s, f"menu patch: no line matched {pattern!r}"
    s = new

def drop_block(pattern):
    global s
    new = re.sub(pattern, "", s, flags=re.M | re.S)
    assert new != s, f"menu patch: block not found: {pattern[:60]!r}"
    s = new

# Learn: Ubuntu docs instead of the Arch wiki
s2 = re.sub(r'\S  Arch\\n', '\uf31b  Ubuntu\\n', s); assert s2 != s; s = s2
drop_line(r'\*Arch\*\) omarchy-launch-webapp "https://wiki\.archlinux\.org')
s = s.replace('  *Omarchy*) omarchy-launch-webapp', '  *Ubuntu*) omarchy-launch-webapp "https://help.ubuntu.com/" ;;\n  *Omarchy*) omarchy-launch-webapp', 1)

# Toggle: direct boot and passwordless sudo are disabled on Ombuntu
drop_option("Direct Boot"); drop_line(r'\*"Direct Boot"\*\)')
drop_option("Passwordless Sudo"); drop_line(r'\*"Passwordless Sudo"\*\)')

# Hardware: hybrid GPU toggle installs Arch NVIDIA packages
drop_block(r'  if omarchy-hw-hybrid-gpu; then\n.*?\n  fi\n\n')
drop_line(r'\*"Hybrid GPU"\*\)')

# Setup > Security and the hibernation entries stay: Ombuntu ships Ubuntu versions of those scripts.

# Install: no AUR, no Windows VM
drop_option("AUR"); drop_line(r'\*AUR\*\) terminal omarchy-pkg-aur-install')
drop_option("Windows"); drop_line(r'\*Windows\*\) present_terminal "omarchy-windows-vm')

# Browsers not packaged for Ubuntu (install and remove menus)
drop_option("Brave Origin"); drop_line(r'\*"Brave Origin"\*\) present_terminal "omarchy-(install|remove)-browser brave-origin"')
drop_option("Zen"); drop_line(r'\*Zen\*\) present_terminal "omarchy-(install|remove)-browser zen"')

# Services: NordVPN comes from its apt repo; ONCE and the Chromium account tweak do not apply
s = s.replace("NordVPN [AUR]", "NordVPN")
drop_option("ONCE"); drop_line(r'\*ONCE\*\) present_terminal omarchy-install-once')
drop_option("Chromium Account"); drop_line(r'\*Chromium\*\) present_terminal omarchy-install-chromium-google-account')

# Editors / AI without an Ubuntu package
drop_option("Cursor"); drop_line(r'\*Cursor\*\) install_and_launch "Cursor"')
drop_option("LM Studio"); drop_line(r'\*Studio\*\) install "LM Studio"')

# Install > Style: remote theme install is disabled
s2 = re.sub(r'(?<=")\S  Theme\\n(?=\S  Background)', '', s); assert s2 != s; s = s2
drop_line(r'\*Theme\*\) present_terminal omarchy-theme-install')

# Remove menu: keep what has an Ubuntu counterpart
drop_option_in("Remove", "Development"); drop_line(r'\*Development\*\) show_remove_development_menu')
drop_option_in("Remove", "Gaming"); drop_line(r'\*Gaming\*\) show_remove_gaming_menu')
drop_option("Preinstalls"); drop_line(r'\*Preinstalls\*\) present_terminal omarchy-remove-preinstalls')

# Update: no release channels, no git-installed extra themes, no Plymouth
drop_option("Channel"); drop_line(r'\*Channel\*\) show_update_channel_menu')
drop_option("Extra Themes"); drop_line(r'\*Themes\*\) present_terminal omarchy-theme-update')
drop_option("Plymouth"); drop_line(r'\*Plymouth\*\) present_terminal omarchy-refresh-plymouth')

# Install > Browser: Firefox from Mozilla's apt repository (the Ubuntu one is a snap)
def add_after_in(menu_title, marker, after_label, new_item):
    """Append '<glyph>  Label' after an existing item, only in the option string of the menu whose line contains marker."""
    global s
    def fix(m):
        line = m.group(0)
        out = re.sub(r'(\S  ' + re.escape(after_label) + r')(?=\\n|")', lambda mm: mm.group(1) + '\\n' + new_item, line, count=1)
        assert out != line, f"menu patch: {after_label!r} not in that menu"
        return out
    new = re.sub(r'^.*menu "' + re.escape(menu_title) + r'" "[^"]*' + re.escape(marker) + r'[^"]*".*$', fix, s, count=1, flags=re.M)
    assert new != s, f"menu patch: menu {menu_title!r} with {marker!r} not found"
    s = new
add_after_in("Install", "Chrome", "Firefox", "\uf269  Firefox (Mozilla apt)")
s2 = s.replace('  *Firefox*) present_terminal "omarchy-install-browser firefox" ;;',
               '  *"Firefox (Mozilla apt)"*) present_terminal "omarchy-install-browser firefox-deb" ;;\n  *Firefox*) present_terminal "omarchy-install-browser firefox" ;;', 1)
assert s2 != s; s = s2

# Install > Apps: the applications behind Omarchy's default shortcuts (Spotify, Obsidian, Typora,
# 1Password, LocalSend, Pinta), which Omarchy preinstalls on Arch and Ombuntu offers on demand.
s2 = re.sub(r'(?<=")(\S  Package\\n)(?=\S  Web App)', lambda m: m.group(1) + '\uf40e  Apps\\n', s, count=1); assert s2 != s; s = s2
s2 = s.replace('  *Package*) terminal omarchy-pkg-install ;;', '  *Package*) terminal omarchy-pkg-install ;;\n  *Apps*) show_install_apps_menu ;;', 1)
assert s2 != s; s = s2
apps_menu = """show_install_apps_menu() {
  case $(menu "Install" "\uf1bc  Spotify\\n\U000f0d5c  Obsidian\\n\uf15c  Typora\\n\U000f07f5  1Password\\n\uf1e0  LocalSend\\n\uf1fc  Pinta") in
  *Spotify*) install_and_launch "Spotify" "spotify" "spotify_spotify" ;;
  *Obsidian*) install_and_launch "Obsidian" "obsidian" "obsidian_obsidian" ;;
  *Typora*) install_and_launch "Typora" "typora" "typora" ;;
  *1Password*) install_and_launch "1Password" "1password" "1password" ;;
  *LocalSend*) install_and_launch "LocalSend" "localsend" "localsend_app" ;;
  *Pinta*) install "Pinta" "pinta" ;;
  *) show_install_menu ;;
  esac
}

"""
s2 = s.replace("show_install_browser_menu() {", apps_menu + "show_install_browser_menu() {", 1); assert s2 != s; s = s2

# No menu extensions (arbitrary user shell sourced into the menu)
drop_line(r'^USER_EXTENSIONS=')
drop_line(r'\$USER_EXTENSIONS')
drop_line(r'^# Allow user extensions and overrides$')

assert s != orig
open(path, "w", encoding="utf-8").write(s)
print("omarchy-menu trimmed for Ubuntu")
