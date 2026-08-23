#!/bin/bash
# Fired by aerospace's exec-on-workspace-change callback.
#
# Does the one aerospace query needed for the whole pill row and hands the
# result to every pill via the event, so the ten pill scripts make no aerospace
# calls of their own. Inlining this in aerospace.toml is not workable — the
# nested quoting breaks the TOML parser.

sketchybar --trigger aerospace_workspace_change \
  FOCUSED_WORKSPACE="$AEROSPACE_FOCUSED_WORKSPACE" \
  PREV_WORKSPACE="$AEROSPACE_PREV_WORKSPACE" \
  NONEMPTY="$(aerospace list-workspaces --monitor all --empty no 2>/dev/null | tr '\n' ' ')" \
  VISIBLE="$(aerospace list-workspaces --monitor all --visible 2>/dev/null | tr '\n' ' ')"
