#!/usr/bin/env bash
# Output volume, with a speaker icon that tracks the level.

# shellcheck source-path=SCRIPTDIR source=../colors.sh
source "${HOME}/.config/sketchybar/colors.sh"

volume="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"

case "${volume}" in
  100 | 9[0-9] | 8[0-9] | 7[0-9] | 6[0-9] | 5[0-9]) icon="" ;; # nf-fa-volume_high
  4[0-9] | 3[0-9] | [1-9] | 1[0-9] | 2[0-9]) icon="" ;;        # nf-fa-volume_low
  *) icon="" ;;                                                # nf-fa-volume_xmark
esac

sketchybar --set "${NAME}" icon="${icon}" icon.color="${AQUA}" label="${volume}%"
