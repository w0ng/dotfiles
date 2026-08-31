#!/bin/bash
# Background daemon (not a sketchybar-invoked plugin) — spawned once from
# sketchybarrc via nohup+disown so it outlives that script's shell.
#
# `media-control stream` blocks on MediaRemote's own change notification
# (the same push Control Center's Now Playing widget uses) and emits a line
# only when something changes, so this sits at ~0 CPU between songs — no
# polling. The line itself is ignored: it's just a "something changed"
# signal, and now_playing.sh re-queries the current truth via a one-shot
# `media-control get` instead of parsing title/artist text out of here (which
# could contain quotes or other characters unsafe to pass through
# `sketchybar --trigger INFO=`). `--no-artwork` skips the several hundred KB
# of base64 album art per line that we'd throw away anyway.
#
# The while-loop restarts `media-control stream` if it ever exits (crash,
# MediaRemote hiccup) instead of silently going dark.
while true; do
  media-control stream --no-artwork 2>/dev/null | while read -r _; do
    sketchybar --trigger now_playing_change
  done
  sleep 1
done
