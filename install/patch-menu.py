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

# Setup: security (fingerprint/fido2) and hibernation are Arch-specific
drop_option("Security"); drop_line(r'\*Security\*\) show_setup_security_menu')
drop_block(r'  if omarchy-hibernation-available; then\n    options="\$options\\n\S  Disable Hibernate"\n  else\n    options="\$options\\n\S  Enable Hibernate"\n  fi\n')
drop_line(r'\*"Enable Hibernate"\*\)'); drop_line(r'\*"Disable Hibernate"\*\)')
drop_line(r'omarchy-hibernation-available && options=.*Hibernate')
drop_line(r'\*Hibernate\*\) systemctl hibernate')

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
drop_line(r'\*Security\*\) show_remove_security_menu')

# Update: no release channels, no git-installed extra themes, no Plymouth
drop_option("Channel"); drop_line(r'\*Channel\*\) show_update_channel_menu')
drop_option("Extra Themes"); drop_line(r'\*Themes\*\) present_terminal omarchy-theme-update')
drop_option("Plymouth"); drop_line(r'\*Plymouth\*\) present_terminal omarchy-refresh-plymouth')

# No menu extensions (arbitrary user shell sourced into the menu)
drop_line(r'^USER_EXTENSIONS=')
drop_line(r'\$USER_EXTENSIONS')
drop_line(r'^# Allow user extensions and overrides$')

assert s != orig
open(path, "w", encoding="utf-8").write(s)
print("omarchy-menu trimmed for Ubuntu")
