#!/usr/bin/env bash
# clip2claude — pull the macOS clipboard image, ship it to a devbox, and type a
# `read <path>` line into the focused kitty window (your herdr Claude pane).
# Bound to a kitty key via:
#   map cmd+p launch --type=background ~/.config/kitty/clip2claude.sh
set -uo pipefail

KITTY_SOCKET="unix:/tmp/mykitty"
REMOTE="/tmp/clip.png"    # where the image lands on the devbox
LOCAL="$(mktemp -t clip).png"
TIFF="${LOCAL%.png}.tiff"

notify() { osascript -e "display notification \"$1\" with title \"clip2claude\"" >/dev/null 2>&1 || true; }

# 0. Detect which devbox the focused window is on, from its running processes
#    (`herdr --remote coder.X`, `coder ssh ... coder.X`, or `kitten ssh coder.X`).
#    One shortcut works for every devbox. recent:0 = the globally-active window.
DEVBOX="$(kitten @ --to "$KITTY_SOCKET" ls --match recent:0 2>/dev/null | python3 -c '
import sys, json, re
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
remote, fallback = "", ""
for osw in data:
    for tab in osw.get("tabs", []):
        for w in tab.get("windows", []):
            for proc in w.get("foreground_processes", []):
                cmd = proc.get("cmdline") or []
                for i, c in enumerate(cmd):
                    if c == "--remote" and i + 1 < len(cmd):
                        remote = cmd[i + 1]
                    elif c.startswith("--remote="):
                        remote = c.split("=", 1)[1]
                    elif not fallback and re.match(r"^coder\.[A-Za-z0-9._-]+$", c):
                        fallback = c
print(remote or fallback)
')"

if [ -z "$DEVBOX" ]; then
  notify "Could not detect the devbox of the focused window"
  exit 0
fi

# 1. Clipboard image -> PNG. Prefer pngpaste (handles TIFF screenshots); else osascript + sips.
get_png() {
  if command -v pngpaste >/dev/null 2>&1; then
    pngpaste "$LOCAL" 2>/dev/null && return 0
    return 1
  fi
  osascript >/dev/null 2>&1 <<EOF || return 1
set f to open for access POSIX file "$TIFF" with write permission
try
  write (the clipboard as «class TIFF») to f
  close access f
on error
  close access f
  error "no image on clipboard"
end try
EOF
  sips -s format png "$TIFF" --out "$LOCAL" >/dev/null 2>&1
}

if ! get_png; then
  notify "No image on clipboard (did you copy a file instead of the image?)"
  exit 0
fi

# 2. Ship it to the devbox.
if ! scp -q "$LOCAL" "$DEVBOX:$REMOTE"; then
  notify "scp to $DEVBOX failed"
  exit 1
fi

# 3. After the upload, type the read command into the focused window (Claude pane).
#    Trailing space, no newline: add your question then press Enter so Claude reads
#    the image and answers in one turn. To auto-submit instead, append $'\r'.
kitten @ --to "$KITTY_SOCKET" send-text --match recent:0 -- "read $REMOTE "

rm -f "$LOCAL" "$TIFF"
