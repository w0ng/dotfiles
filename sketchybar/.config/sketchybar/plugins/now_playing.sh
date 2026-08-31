#!/bin/bash
# Now playing: "title — artist", dimmed while paused.
#
# Driven by the custom now_playing_change event (fired by
# now_playing_stream.sh whenever MediaRemote reports a change) plus
# system_woke, in case a change lands while asleep. This runs one `media-control
# get` per actual change — never on a timer — so it stays cheap.

source "$HOME/.config/sketchybar/colors.sh"

# MAX_LEN=48
MAX_LEN=85

info=$(media-control get --no-artwork 2>/dev/null)

# Three lines from one jq call, read one at a time: splitting a single
# tab/space-joined line via IFS would silently misparse an empty title,
# since bash's whitespace-IFS read collapses leading empty fields.
{
  IFS= read -r title
  IFS= read -r artist
  IFS= read -r playing
} < <(jq -r '.title // "", .artist // "", (.playing // false)' <<< "$info")

if [ -z "$title" ]; then
  sketchybar --set "$NAME" icon.drawing=off label=""
  exit 0
fi

text="$title"
[ -n "$artist" ] && text="$title — $artist"
if [ "${#text}" -gt "$MAX_LEN" ]; then
  text="${text:0:$((MAX_LEN - 1))}…"
fi

if [ "$playing" = "true" ]; then
  color="$SPOTIFY_GREEN"
else
  color="$GRAY"
fi

sketchybar --set "$NAME" icon.drawing=on icon="" icon.color="$color" \
                         label="$text" label.color="$color"
