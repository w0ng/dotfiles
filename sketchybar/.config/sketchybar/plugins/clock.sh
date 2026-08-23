#!/bin/bash
# Date and 12-hour time, e.g. "Mon 24 Aug  1:04 am".
#
# %-I drops the leading zero on the hour; %l would blank-pad it instead, which
# leaves a visible gap after the date. BSD date has no lowercase am/pm
# specifier (%P is a GNU extension), hence the sed.
sketchybar --set "$NAME" label="$(date '+%a %d %b  %-I:%M %p' | sed 's/AM$/am/; s/PM$/pm/')"
