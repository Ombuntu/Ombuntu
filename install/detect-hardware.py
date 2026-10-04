#!/usr/bin/env python3
"""Print detected keyboard layout and display scaling for a first install.

Output (one per line):  key=value
  kb_layout, kb_variant   from the system console/X keyboard config (empty if unset)
  scale, gdk_scale        1 / 1.6+1.75 / 2+2, from the internal panel's EDID size and mode
  panel                   connector and mode used for the decision, or "none"
  render_card             on a multi-GPU machine, the stable /dev/dri/by-path path of the
                          GPU that owns the connected display; empty when there is one GPU,
                          no display, or displays spread across several GPUs
"""
import glob, os, re, shlex, subprocess

def keyboard():
    layout = variant = ""
    for src in ("/etc/default/keyboard", "/etc/vconsole.conf"):
        try:
            for line in open(src):
                m = re.match(r'^\s*(XKBLAYOUT|XKBVARIANT)\s*=\s*"?([^"\n]*)"?', line)
                if m:
                    if m.group(1) == "XKBLAYOUT" and not layout: layout = m.group(2).strip()
                    if m.group(1) == "XKBVARIANT" and not variant: variant = m.group(2).strip()
        except OSError:
            pass
        if layout: break
    # XFCE's own setting wins when the user changed it there
    try:
        out = subprocess.run(["xfconf-query", "-c", "keyboard-layout", "-p", "/Default/XkbLayout"],
                             capture_output=True, text=True, timeout=5)
        if out.returncode == 0 and out.stdout.strip():
            layout = out.stdout.strip()
            v = subprocess.run(["xfconf-query", "-c", "keyboard-layout", "-p", "/Default/XkbVariant"],
                               capture_output=True, text=True, timeout=5)
            variant = v.stdout.strip() if v.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        pass
    return layout, variant

def panels():
    found = []
    for st in sorted(glob.glob("/sys/class/drm/card*-*/status")):
        d = os.path.dirname(st)
        try:
            if open(st).read().strip() != "connected": continue
            modes = open(d + "/modes").read().split()
            edid = open(d + "/edid", "rb").read()
        except OSError:
            continue
        if not modes: continue
        m = re.match(r"^(\d+)x(\d+)", modes[0])
        w, h = (int(m.group(1)), int(m.group(2))) if m else (0, 0)
        wcm = edid[21] if len(edid) >= 128 else 0
        dpi = w / (wcm / 2.54) if wcm else 0
        found.append((os.path.basename(d), modes[0], dpi))
    # prefer the built-in panel, then anything else
    found.sort(key=lambda p: (0 if "eDP" in p[0] or "LVDS" in p[0] else 1))
    return found

def render_card():
    """The GPU the monitors are plugged into.

    With two GPUs, aquamarine may pick the one driving nothing -- an iGPU with only a
    Writeback connector, say -- and then every frame is copied to the other card for
    scanout, on the CPU. Naming the right card up front avoids that. Only decided when
    every connected display hangs off one card: with outputs on several GPUs, pinning
    one would blank the others, so leave the choice to aquamarine.
    """
    cards = {os.path.basename(c) for c in glob.glob("/sys/class/drm/card[0-9]*")
             if "-" not in os.path.basename(c)}
    if len(cards) < 2:
        return ""
    owners = set()
    for st in glob.glob("/sys/class/drm/card*-*/status"):
        try:
            if open(st).read().strip() != "connected":
                continue
        except OSError:
            continue
        owners.add(os.path.basename(os.path.dirname(st)).split("-", 1)[0])
    if len(owners) != 1:
        return ""
    card = owners.pop()
    for link in sorted(glob.glob("/dev/dri/by-path/*-card")):
        try:
            if os.path.basename(os.path.realpath(link)) == card:
                return link
        except OSError:
            pass
    return ""

def emit(k, v): print(f"{k}={shlex.quote(str(v))}")   # safe to eval in bash

layout, variant = keyboard()
emit("kb_layout", layout); emit("kb_variant", variant)
ps = panels()
if ps:
    name, mode, dpi = ps[0]
    if dpi >= 180:   scale, gdk = "2", "2"
    elif dpi >= 150: scale, gdk = "1.6", "1.75"
    else:            scale, gdk = "1", "1"
    emit("scale", scale); emit("gdk_scale", gdk); emit("panel", f"{name} {mode} {dpi:.0f}dpi")
else:
    emit("scale", "1"); emit("gdk_scale", "1"); emit("panel", "none")
emit("render_card", render_card())
