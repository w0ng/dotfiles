#!/usr/bin/env bash
#
# Tests for the sketchybar plugins.
#
# Run from the repository root:
#
#   bash tests/sketchybar_test.sh
#
# Each test builds a scratch $HOME holding the real colors.sh and icon helpers,
# and puts stub `aerospace` and `sketchybar` binaries first on PATH, so nothing
# here touches the running bar. The aerospace stub replays a fixed listing and
# the sketchybar stub logs its argv, which makes the assertions about what the
# bar would be told to draw rather than about how the script got there.
#
# The fixtures stay separate from bootstrap_test.sh, which sources bootstrap.sh
# and stubs a different set of tools. Only harness.sh is shared, and it holds
# the assertions and the runner.

# shellcheck source-path=SCRIPTDIR source=./harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"
readonly PLUGIN_DIR="${REPO_ROOT}/sketchybar/.config/sketchybar/plugins"
readonly HELPER_DIR="${REPO_ROOT}/sketchybar/.config/sketchybar/helpers"

# These repeat colors.sh rather than sourcing it, so a wrong edit there fails a
# test instead of changing both sides of the comparison at once.
readonly BAR=0xf01d2021
readonly BG0=0xff282828
readonly FG=0xffebdbb2
readonly GRAY=0xffa89984
readonly GRAY_DARK=0xff7c6f64
readonly YELLOW=0xfffabd2f
readonly BLUE=0xff83a598
readonly GREEN=0xffb8bb26
readonly RED=0xfffb4934
readonly ORANGE=0xfffe8019
readonly PURPLE=0xffd3869b
readonly DIM=0xff665c54

setup() {
  WORK_DIR="$(mktemp -d)"
  STUB_LOG="${WORK_DIR}/calls.log"
  : >"${STUB_LOG}"

  mkdir -p "${WORK_DIR}/stubs" "${WORK_DIR}/home/.config/sketchybar/helpers"
  cp "${REPO_ROOT}/sketchybar/.config/sketchybar/colors.sh" \
    "${WORK_DIR}/home/.config/sketchybar/colors.sh"
  cp "${REPO_ROOT}/sketchybar/.config/sketchybar/helpers/icon_map.sh" \
    "${WORK_DIR}/home/.config/sketchybar/helpers/icon_map.sh"
  cp "${REPO_ROOT}/sketchybar/.config/sketchybar/helpers/icon_colors.sh" \
    "${WORK_DIR}/home/.config/sketchybar/helpers/icon_colors.sh"

  cat >"${WORK_DIR}/stubs/aerospace" <<'STUB'
#!/bin/bash
printf '%s\n' "${STUB_AEROSPACE:-}"
exit 0
STUB
  cat >"${WORK_DIR}/stubs/sketchybar" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >>"${STUB_LOG}"
exit 0
STUB
  # ai_watch.py refuses to start without herdr on PATH, so the suite needs one
  # even though the watcher then speaks to the socket rather than the binary.
  cat >"${WORK_DIR}/stubs/herdr" <<'STUB'
#!/bin/bash
exit 0
STUB
  chmod +x "${WORK_DIR}/stubs/"*

  # Past the guard above, the watcher speaks the API over a unix socket and
  # never shells out, so the counts have to come from a real socket.
  cat >"${WORK_DIR}/fake_herdr.py" <<'FAKE'
import json, os, socket, sys
path = sys.argv[1]
agents = json.loads(os.environ["STUB_AGENTS"])
server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(path)
server.listen(16)
while True:
    conn, _ = server.accept()
    try:
        conn.recv(65536)
        conn.sendall((json.dumps({"id": "x", "result": {"agents": agents}}) + "\n").encode())
    except Exception:
        pass
    finally:
        conn.close()
FAKE

  export STUB_LOG
}

teardown() {
  [[ -n "${FAKE_SERVER:-}" ]] && kill "${FAKE_SERVER}" 2>/dev/null
  # ai_watch.py puts itself in its own session, so it has no parent to kill it
  # through. Matching the script name alone would also match the watcher running
  # the real bar, so each candidate is checked against this test's own socket,
  # which `ps eww` exposes in its environment.
  local pid
  for pid in $(pgrep -f "ai_watch.py" 2>/dev/null); do
    if ps eww -p "${pid}" 2>/dev/null | grep -q "HERDR_SOCKET_PATH=${WORK_DIR}/"; then
      kill "${pid}" 2>/dev/null
    fi
  done
  [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
  return 0
}

# Runs the plugin the way sketchybar would, with $1 as the listing the aerospace
# stub replays. The value goes on the command rather than into an export, so no
# test can leak a fixture into the next one.
paint_with() {
  STUB_AEROSPACE="$1" PATH="${WORK_DIR}/stubs:${PATH}" HOME="${WORK_DIR}/home" \
    bash "${PLUGIN_DIR}/aerospace.sh"
}

# Runs front_app.sh the way sketchybar would, with $1 as the app name the
# front_app_switched event carries. An empty $1 leaves $INFO unset, which is
# what sends the plugin to its aerospace fallback.
front_app_with() {
  STUB_AEROSPACE="${2-}" INFO="$1" NAME=front_app \
    PATH="${WORK_DIR}/stubs:${PATH}" HOME="${WORK_DIR}/home" \
    bash "${PLUGIN_DIR}/front_app.sh"
}

# Workspace 1 focused, 2 has windows but is off-screen, 3 visible on the other
# monitor, 4 empty. Two monitors, main focused, tiled, main binding mode.
fixture() {
  printf 'M\ttrue\t1\n'
  printf 'W\th_tiles\tfalse\n'
  printf 'A\t1\ttrue\ttrue\n'
  printf 'A\t2\tfalse\tfalse\n'
  printf 'A\t3\ttrue\tfalse\n'
  printf 'A\t4\tfalse\tfalse\n'
  printf 'N\t1\n'
  printf 'N\t2\n'
  printf '2\n'
  printf 'main\n'
}

#######################################
# Tests
#######################################

test_the_whole_repaint_is_one_sketchybar_process() {
  paint_with "$(fixture)"

  assert_eq '1' "$(calls | wc -l | tr -d ' ')" \
    'every item is painted by a single sketchybar process'
}

test_focused_workspace_pill_is_highlighted() {
  paint_with "$(fixture)"

  assert_contains "$(calls)" \
    "--set space.1 background.drawing=on background.color=${YELLOW} label.color=${BG0}" \
    'the focused pill takes the yellow background'
}

test_workspace_visible_on_another_monitor_is_distinct() {
  paint_with "$(fixture)"

  assert_contains "$(calls)" \
    "--set space.3 background.drawing=on background.color=${GRAY_DARK} label.color=${FG}" \
    'a pill visible elsewhere is neither focused nor idle'
}

test_workspace_with_windows_reads_as_occupied() {
  paint_with "$(fixture)"

  assert_contains "$(calls)" \
    "--set space.2 background.drawing=on background.color=${BAR} label.color=${FG}" \
    'an off-screen workspace holding windows keeps full-strength text'
}

test_empty_workspace_recedes() {
  paint_with "$(fixture)"

  assert_contains "$(calls)" \
    "--set space.4 background.drawing=on background.color=${BAR} label.color=${DIM}" \
    'a workspace with no windows is dimmed'
}

test_layout_is_reported_verbatim() {
  paint_with "$(fixture)"

  assert_contains "$(calls)" "label=h_tiles label.color=${GREEN}" \
    "AeroSpace's own layout name reaches the bar unmapped"
}

test_fullscreen_overrides_the_layout_name() {
  paint_with "$(printf 'M\ttrue\t1\nW\th_tiles\ttrue\nA\t1\ttrue\ttrue\nN\t1\n2\nmain\n')"

  assert_contains "$(calls)" "label=fullscreen label.color=${ORANGE}" \
    'a fullscreen window is reported instead of the underlying layout'
}

# An empty workspace produces no window-* fields at all, which is the case the
# tagged output exists to survive.
test_missing_window_line_falls_back_to_a_placeholder() {
  paint_with "$(printf 'M\ttrue\t1\nA\t1\ttrue\ttrue\n2\nmain\n')"

  assert_contains "$(calls)" "label=— label.color=${GRAY}" \
    'no focused window leaves a placeholder rather than an empty label'
}

test_single_display_hides_the_monitor_pill() {
  paint_with "$(printf 'M\ttrue\t1\nW\th_tiles\tfalse\nA\t1\ttrue\ttrue\nN\t1\n1\nmain\n')"

  assert_contains "$(calls)" '--set monitor drawing=off' \
    'a monitor pill that could only ever read monitor_1 is hidden'
}

test_two_displays_show_the_monitor_pill() {
  paint_with "$(fixture)"

  assert_contains "$(calls)" '--set monitor drawing=on' \
    'the monitor pill is drawn once there is a choice of display'
}

# The count line absent entirely, which the `:-2` default catches. A count that
# is present but not a number cannot be reached from here: the parse loop sends
# any `*[!0-9]*` token to `mode`, so no fixture can put one in monitor_count.
# See the comment on that comparison in aerospace.sh.
test_missing_monitor_count_still_draws() {
  paint_with "$(printf 'M\ttrue\t1\nW\th_tiles\tfalse\nA\t1\ttrue\ttrue\nN\t1\nmain\n')"

  assert_contains "$(calls)" '--set monitor drawing=on' \
    'a missing count defaults to drawing the pill'
}

test_a_non_main_display_is_coloured_apart() {
  paint_with "$(printf 'M\tfalse\t2\nW\th_tiles\tfalse\nA\t1\ttrue\ttrue\nN\t1\n2\nmain\n')"

  assert_contains "$(calls)" \
    "icon.color=${PURPLE} label=monitor_2 label.color=${PURPLE}" \
    'the bar colours a non-main display apart from the main one'
}

# list-monitors --focused always returns a line, so this guards the fallback
# rather than a live failure.
test_missing_monitor_line_falls_back_to_a_placeholder() {
  paint_with "$(printf 'W\th_tiles\tfalse\nA\t1\ttrue\ttrue\nN\t1\n2\nmain\n')"

  assert_contains "$(calls)" \
    "icon=󰍹 icon.color=${GRAY} label=— label.color=${GRAY}" \
    'no monitor id leaves a placeholder rather than a bare "monitor_"'
}

test_main_binding_mode_is_hidden() {
  paint_with "$(fixture)"

  assert_contains "$(calls)" '--set mode drawing=off' \
    'the default mode takes no space on the bar'
}

test_other_binding_modes_are_announced() {
  paint_with "$(printf 'M\ttrue\t1\nW\th_tiles\tfalse\nA\t1\ttrue\ttrue\nN\t1\n2\nservice\n')"

  assert_contains "$(calls)" "--set mode drawing=on label=SERVICE label.color=${BG0} background.color=${RED}" \
    'a non-default mode is drawn in upper case'
}

# Only main and service exist today, so this guards the discrimination rather
# than a live failure: an untagged line is told from a tagged one by whether it
# carries fields, so a mode name may collide with a tag without taking its arm.
test_a_mode_named_like_a_line_tag_does_not_take_its_arm() {
  paint_with "$(printf 'M\ttrue\t3\nW\th_tiles\tfalse\nA\t1\ttrue\ttrue\nN\t1\n2\nM\n')"

  assert_contains "$(calls)" 'label=monitor_3' \
    'the real monitor line survives a mode of the same name'
  assert_contains "$(calls)" '--set mode drawing=on label=M' \
    'the colliding name is still read as the mode'
}

# A failed query leaves every item at its last paint. Blanking the whole bar on
# a brief AeroSpace restart would be worse than showing stale state.
test_a_failed_query_paints_nothing() {
  paint_with ''

  assert_eq '' "$(calls)" 'no output means no repaint at all'
}

#######################################
# front_app
#######################################

# The ligature the app font renders as the app's icon. It only becomes a glyph
# once icon.font is the app font, which sketchybarrc sets on this item alone.
test_front_app_shows_the_app_glyph_beside_its_name() {
  front_app_with 'Ghostty'

  assert_contains "$(calls)" '--set front_app icon=:ghostty:' \
    'the icon ligature is painted alongside the app name'
  assert_contains "$(calls)" 'label=Ghostty' 'the app name is the label'
}

# The glyph is a flat silhouette, so the app's own colour has to come from here.
test_a_mapped_app_takes_its_own_colour() {
  front_app_with 'Brave Browser'

  assert_contains "$(calls)" 'icon=:brave_browser: icon.color=0xffec622c' \
    "Brave's glyph is painted in Brave's orange"
}

# A black-and-white icon has no colour to borrow, so the table records $FG. An
# unmapped app resolves to the same colour, so only the ligature separates them.
test_an_achromatic_icon_takes_the_foreground() {
  front_app_with 'ChatGPT'

  assert_contains "$(calls)" "icon=:openai: icon.color=${FG}" \
    'a monochrome icon is drawn in the bar foreground'
}

# Every app without a glyph shares :default:, so there is nothing to key a
# colour on and it falls back to $FG.
test_an_app_with_no_colour_of_its_own_takes_the_foreground() {
  front_app_with 'No Such App'

  assert_contains "$(calls)" "icon.color=${FG}" \
    'an unmapped app is drawn in the foreground'
  assert_not_contains "$(calls)" "icon.color=${YELLOW}" \
    'the accent is not the fallback'
}

# The table is generated, so this guards the rule every value in it was picked
# for rather than any one value. A colour that cannot be read on the bar is the
# one way sampling an icon can go wrong: artwork is often darker than the bar.
test_every_colour_in_the_table_can_be_read_on_the_bar() {
  local table="${REPO_ROOT}/sketchybar/.config/sketchybar/helpers/icon_colors.sh"
  local channels result ratio worst

  # Hex is unpacked here because BSD awk has no strtonum, leaving awk the
  # floating-point part: WCAG relative luminance against $BAR, alpha dropped.
  channels="$(grep -oE 'color_result=0xff[0-9a-f]{6}' "${table}" \
    | sed 's/.*0xff//' \
    | while read -r hex; do
      printf '%s %d %d %d\n' "${hex}" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
    done)"

  [[ -n "${channels}" ]] || fail 'no colours found in the table'

  result="$(printf '%s\n' "${channels}" | awk '
    function srgb(c) {
      c /= 255
      return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4
    }
    function luminance(r, g, b) {
      return 0.2126 * srgb(r) + 0.7152 * srgb(g) + 0.0722 * srgb(b)
    }
    BEGIN { bg = luminance(29, 32, 33); min = 1000 }
    {
      ratio = (luminance($2, $3, $4) + 0.05) / (bg + 0.05)
      if (ratio < min) { min = ratio; worst = $1 }
    }
    END { printf "%d %s\n", min * 100, worst }')"

  ratio="${result%% *}"
  worst="${result##* }"
  [[ "${ratio}" -ge 450 ]] \
    || fail "#${worst} is ${ratio} hundredths of a contrast ratio against the bar, under 4.50"
}

# The vendored map covers ~600 apps, so anything else still needs an icon
# rather than a blank.
test_an_unmapped_app_falls_back_to_the_default_glyph() {
  front_app_with 'No Such App'

  assert_contains "$(calls)" '--set front_app icon=:default:' \
    'an app with no icon of its own still gets one'
}

# sketchybar passes $INFO only for front_app_switched. On a reload or a manual
# trigger there is none, and AeroSpace has to be asked instead.
test_a_missing_info_falls_back_to_aerospace() {
  front_app_with '' 'Ghostty'

  assert_contains "$(calls)" '--set front_app icon=:ghostty:' \
    'the fallback query paints the same pair'
}

test_no_focused_app_paints_nothing() {
  front_app_with '' ''

  assert_eq '' "$(calls)" 'an empty app name leaves the last paint alone'
}

#######################################
# ai_agents
#######################################

# Runs the plugin with $1 as the contents of the file helpers/ai_watch.py
# maintains. No argument means no file at all, which is what a machine with the
# watcher not yet running looks like.
ai_paint_with() {
  local state_dir="${WORK_DIR}/home/.cache/sketchybar"
  mkdir -p "${state_dir}"
  if [[ $# -gt 0 ]]; then
    printf '%s' "$1" >"${state_dir}/ai_agents"
  else
    rm -f "${state_dir}/ai_agents"
  fi
  PATH="${WORK_DIR}/stubs:${PATH}" HOME="${WORK_DIR}/home" \
    XDG_CACHE_HOME="${WORK_DIR}/home/.cache" \
    bash "${PLUGIN_DIR}/ai_agents.sh"
}

# Three working, one blocked, two finished-but-unseen, one idle.
ai_fixture() {
  printf 'total=7\nworking=3\nblocked=1\ndone=2\nidle=1\n'
}

test_ai_the_whole_group_is_one_sketchybar_process() {
  ai_paint_with "$(ai_fixture)"

  assert_eq '1' "$(calls | wc -l | tr -d ' ')" \
    'five items are painted by a single sketchybar process'
}

test_ai_counts_are_drawn_per_state() {
  ai_paint_with "$(ai_fixture)"

  assert_contains "$(calls)" \
    "--set ai.working drawing=on icon=󰭻 icon.color=${BLUE} label=3 label.color=${BLUE}" \
    'working agents are counted in blue'
  assert_contains "$(calls)" \
    "--set ai.blocked drawing=on icon=󱜸 icon.color=${RED} label=1 label.color=${RED}" \
    'an agent waiting on you is counted in red'
  assert_contains "$(calls)" \
    "--set ai.done drawing=on icon=󱐏 icon.color=${GREEN} label=2 label.color=${GREEN}" \
    'a finished turn nobody has looked at is counted in green'
}

# Idle is a count like any other, not a fallback shown only when nothing else is.
test_ai_idle_is_counted_alongside_the_rest() {
  ai_paint_with "$(ai_fixture)"

  assert_contains "$(calls)" \
    "--set ai.idle drawing=on icon=󱋑 icon.color=${DIM} label=1 label.color=${DIM}" \
    'idle agents are counted whether or not others are busy'
}

test_ai_the_robot_leads_the_group() {
  ai_paint_with "$(ai_fixture)"

  assert_contains "$(calls)" "--set ai.icon drawing=on icon= icon.color=${PURPLE}" \
    'the robot is drawn once any agent exists'
}

test_ai_a_state_with_no_agents_is_hidden() {
  ai_paint_with "$(printf 'total=2\nworking=2\nblocked=0\ndone=0\nidle=0\n')"

  assert_contains "$(calls)" '--set ai.blocked drawing=off' \
    'no blocked agents, so no blocked count'
  assert_contains "$(calls)" '--set ai.done drawing=off' \
    'no finished agents, so no done count'
  assert_contains "$(calls)" '--set ai.idle drawing=off' \
    'no idle agents, so no idle count'
  assert_contains "$(calls)" 'label=2' 'the state that has agents is still drawn'
}

# The whole point of the total: with no agents the bar goes back to what it was.
test_ai_no_agents_hides_every_item() {
  ai_paint_with "$(printf 'total=0\nworking=0\nblocked=0\ndone=0\nidle=0\n')"

  assert_contains "$(calls)" '--set ai.icon drawing=off' 'the robot is hidden too'
  assert_not_contains "$(calls)" 'drawing=on' 'nothing at all is drawn'
}

# The watcher has not run yet, or its cache was cleared. Either way there is
# nothing to report, and a robot with no counts beside it would be worse.
test_ai_a_missing_state_file_hides_every_item() {
  ai_paint_with

  assert_contains "$(calls)" '--set ai.icon drawing=off' \
    'no state file hides the group'
  assert_not_contains "$(calls)" 'drawing=on' 'nothing at all is drawn'
}

# Cut before any `=`, so no case arm matches and every count keeps its zero.
test_ai_a_truncated_state_file_hides_every_item() {
  ai_paint_with "$(printf 'tot')"

  assert_not_contains "$(calls)" 'drawing=on' \
    'a file cut before any value is treated as no agents'
}

# What the digits-only guard is for. `$(( ))` dereferences a bare word, so an
# unguarded `working=idle` would silently add this reading's idle count. The
# guard costs the corrupt state its own count, and the rest still draw.
test_ai_a_non_numeric_count_costs_only_its_own_state() {
  ai_paint_with "$(printf 'working=idle\nblocked=0\ndone=0\nidle=1\n')"

  assert_contains "$(calls)" '--set ai.working drawing=off' \
    'the corrupt count reads as none of that state'
  assert_contains "$(calls)" \
    "--set ai.idle drawing=on icon=󱋑 icon.color=${DIM} label=1 label.color=${DIM}" \
    'the states that parsed are still drawn'
}

# The total is derived, so a contributor that names none of its own still gets
# counted rather than hiding the group.
test_ai_counts_without_a_total_still_draw() {
  ai_paint_with "$(printf 'working=2\n')"

  assert_contains "$(calls)" '--set ai.icon drawing=on' \
    'a file naming no total still draws what it does name'
}

# Writes one contributor file, the way a watcher of a herd this machine cannot
# reach does. A third argument backdates it, which is how a writer that has
# stopped is told apart from one still reporting.
ai_contributor() {
  local dir="${WORK_DIR}/home/.cache/sketchybar/ai_agents.d"
  mkdir -p "${dir}"
  printf '%s' "$2" >"${dir}/$1"
  # A negative offset dates the file forward instead, which is what a clock
  # that stepped back or a copy from a host running ahead leaves behind.
  if [[ $# -gt 2 ]]; then
    local sign='-' secs="$3"
    if [[ "${secs}" == -* ]]; then
      sign='+'
      secs="${secs#-}"
    fi
    touch -t "$(date -v"${sign}${secs}"S '+%Y%m%d%H%M.%S')" "${dir}/$1"
  fi
}

# Two working, one blocked and one idle, on a machine this bar cannot see.
ai_contributor_fixture() {
  printf 'total=4\nworking=2\nblocked=1\ndone=0\nidle=1\n'
}

test_ai_a_contributor_adds_to_the_local_counts() {
  ai_contributor remotes "$(ai_contributor_fixture)"
  ai_paint_with "$(ai_fixture)"

  assert_contains "$(calls)" \
    "--set ai.working drawing=on icon=󰭻 icon.color=${BLUE} label=5 label.color=${BLUE}" \
    'three working here and two elsewhere are drawn as one count of five'
  assert_contains "$(calls)" \
    "--set ai.blocked drawing=on icon=󱜸 icon.color=${RED} label=2 label.color=${RED}" \
    'one blocked on each side adds up rather than overwriting'
}

# Nothing running locally, so the group has to appear for a herd that is only
# reachable through a contributor.
test_ai_a_contributor_alone_draws_the_group() {
  ai_contributor remotes "$(ai_contributor_fixture)"
  ai_paint_with "$(printf 'total=0\nworking=0\nblocked=0\ndone=0\nidle=0\n')"

  assert_contains "$(calls)" "--set ai.icon drawing=on icon= icon.color=${PURPLE}" \
    'the robot is drawn for agents this machine cannot see itself'
}

# The mtime is a heartbeat, because a contributor rewrites its file every
# cycle. One that has gone quiet is a writer that died, not a herd sitting
# still, and counting it on would report agents that are already gone.
test_ai_a_stale_contributor_is_left_out() {
  ai_contributor remotes "$(ai_contributor_fixture)" 90
  ai_paint_with "$(ai_fixture)"

  assert_contains "$(calls)" \
    "--set ai.working drawing=on icon=󰭻 icon.color=${BLUE} label=3 label.color=${BLUE}" \
    'a contributor that stopped writing stops counting'
}

# The same guard on a contributor, which is the file it exists for, being
# written by tooling this repo does not own.
test_ai_a_corrupt_contributor_count_costs_only_its_own_state() {
  # shellcheck disable=SC2016  # the payload has to reach the plugin unexpanded
  ai_contributor remotes "$(printf 'working=x[$(exit 7)]\nidle=1\n')"
  ai_paint_with "$(ai_fixture)"

  assert_contains "$(calls)" \
    "--set ai.working drawing=on icon=󰭻 icon.color=${BLUE} label=3 label.color=${BLUE}" \
    'the corrupt remote count adds nothing'
  assert_contains "$(calls)" \
    "--set ai.idle drawing=on icon=󱋑 icon.color=${DIM} label=2 label.color=${DIM}" \
    'the count beside it still adds'
}

# A contributor's half-written temp file. `*` does not match a leading dot,
# which is what keeps the temp file from being summed with the finished one and
# doubling every count.
test_ai_a_dotfile_beside_a_contributor_is_not_counted() {
  ai_contributor remotes "$(ai_contributor_fixture)"
  ai_contributor .remotes.part "$(ai_contributor_fixture)"
  ai_paint_with "$(printf 'working=0\nblocked=0\ndone=0\nidle=0\n')"

  assert_contains "$(calls)" \
    "--set ai.working drawing=on icon=󰭻 icon.color=${BLUE} label=2 label.color=${BLUE}" \
    'the temp file is not counted alongside the file it will become'
}

# Why the mtime is read as a heartbeat at all. A herd nobody watches any more
# has to leave the bar rather than stay on it.
test_ai_a_stale_contributor_alone_hides_every_item() {
  ai_contributor remotes "$(ai_contributor_fixture)" 90
  ai_paint_with "$(printf 'working=0\nblocked=0\ndone=0\nidle=0\n')"

  assert_contains "$(calls)" '--set ai.icon drawing=off' \
    'a dead contributor leaves no robot behind'
  assert_not_contains "$(calls)" 'drawing=on' 'nothing at all is drawn'
}

# `-le` alone passes every negative age, so a file dated ahead of this machine
# would never expire and would count on long after its writer had died.
test_ai_a_contributor_dated_into_the_future_is_left_out() {
  ai_contributor remotes "$(ai_contributor_fixture)" -3600
  ai_paint_with "$(ai_fixture)"

  assert_contains "$(calls)" \
    "--set ai.working drawing=on icon=󰭻 icon.color=${BLUE} label=3 label.color=${BLUE}" \
    'a contributor dated ahead of this machine counts for nothing'
}

# Counts add between files, never within one. A writer that appends rather than
# truncating leaves its old reading above its new one, and adding the two would
# report a herd bigger than any it ever saw.
test_ai_a_repeated_key_in_one_file_takes_the_last_value() {
  ai_paint_with "$(printf 'working=9\nworking=2\n')"

  assert_contains "$(calls)" \
    "--set ai.working drawing=on icon=󰭻 icon.color=${BLUE} label=2 label.color=${BLUE}" \
    'the second reading replaces the first rather than adding to it'
}

# The digits-only guard passes any length, and 10# on twenty of them wraps
# through signed 64-bit. Drawn, the wrap is a nonsense label; summed, a value
# chosen to wrap negative hides the group while agents are still running.
test_ai_an_oversized_count_reads_as_none() {
  ai_paint_with "$(printf 'working=99999999999999999999\nidle=1\n')"

  assert_contains "$(calls)" '--set ai.working drawing=off' \
    'a count too large to be real is not drawn'
  assert_contains "$(calls)" \
    "--set ai.idle drawing=on icon=󱋑 icon.color=${DIM} label=1 label.color=${DIM}" \
    'the count beside it still draws'
}

# Where the overlay adds its own items. The hook has to sit after the
# declarations, so it can reconfigure an item this file already made, and
# before --update, since an item declared after it is never painted until
# something else triggers the group.
test_ai_the_local_hook_is_sourced_last_but_before_the_first_paint() {
  local rc hook update last_item
  rc="${REPO_ROOT}/sketchybar/.config/sketchybar/sketchybarrc"
  hook="$(grep -n 'sketchybarrc\.local' "${rc}" | tail -1 | cut -d: -f1)"
  # Anchored on the command, because the file also discusses --update in
  # comments, and the first of those sits above the hook.
  update="$(grep -n '^sketchybar --update' "${rc}" | head -1 | cut -d: -f1)"
  last_item="$(grep -n -- '--add item' "${rc}" | tail -1 | cut -d: -f1)"

  # Each anchor is checked for itself, so a renamed line fails saying so rather
  # than leaving an empty operand to read as line zero.
  if [[ -z "${hook}" || -z "${update}" || -z "${last_item}" ]]; then
    fail "an anchor moved: hook=[${hook}] update=[${update}] item=[${last_item}]"
    return
  fi
  if [[ "${hook}" -lt "${last_item}" ]]; then
    fail 'the hook is sourced before the items it is meant to be able to change'
  fi
  if [[ "${hook}" -gt "${update}" ]]; then
    fail 'the hook is sourced after --update, so its items never paint'
  fi
}

#######################################
# ai_watch
#######################################

# Runs the watcher against a fake herdr socket replying with $1 as the
# agent.list payload, and returns once it has written the state file.
ai_watch_with() {
  local agents="$1" state_dir="${WORK_DIR}/home/.cache/sketchybar"
  local sock="${WORK_DIR}/herdr.sock"

  STUB_AGENTS="${agents}" python3 "${WORK_DIR}/fake_herdr.py" "${sock}" >/dev/null 2>&1 &
  FAKE_SERVER=$!
  wait_for "${sock}" || fail 'the fake herdr socket never appeared'

  # Both children must give up this function's stdout, or the command
  # substitution that captures the state file waits forever on a pipe the
  # watcher is still holding open.
  HERDR_SOCKET_PATH="${sock}" XDG_CACHE_HOME="${WORK_DIR}/home/.cache" \
    HOME="${WORK_DIR}/home" PATH="${WORK_DIR}/stubs:${PATH}" \
    python3 "${HELPER_DIR}/ai_watch.py" >/dev/null 2>&1 &
  wait_for "${state_dir}/ai_agents" \
    || fail 'the watcher never wrote its state file'
  cat "${state_dir}/ai_agents" 2>/dev/null
}

# Bounded wait so a failure reports rather than hanging the suite.
wait_for() {
  local path="$1" i=0
  while [[ ! -e "${path}" ]] && ((i < 100)); do
    sleep 0.05
    i=$((i + 1))
  done
  [[ -e "${path}" ]]
}

test_ai_watch_tallies_each_status_reported_by_herdr() {
  local out
  out="$(ai_watch_with '[
    {"agent_status":"working"},{"agent_status":"working"},
    {"agent_status":"blocked"},
    {"agent_status":"done"},
    {"agent_status":"idle"}
  ]')"

  assert_contains "${out}" 'total=5' 'every agent herdr lists is counted'
  assert_contains "${out}" 'working=2' 'working agents are tallied'
  assert_contains "${out}" 'blocked=1' 'blocked agents are tallied'
  assert_contains "${out}" 'done=1' 'done is its own count, not folded into idle'
  assert_contains "${out}" 'idle=1' 'idle agents are tallied'
}

# unknown is what a pane reports for a second or two before herdr recognises the
# agent, so it must not earn a colour of its own and flicker on the bar.
test_ai_watch_reads_unknown_as_idle() {
  local out
  out="$(ai_watch_with '[{"agent_status":"unknown"},{"agent_status":"idle"}]')"

  assert_contains "${out}" 'total=2' 'an unrecognised agent still counts toward the total'
  assert_contains "${out}" 'idle=2' 'unknown is reported as idle'
}

# The design's headline claim: the bar is told only when the counts move.
test_ai_watch_triggers_the_bar_once_for_a_reading() {
  local i=0
  ai_watch_with '[{"agent_status":"working"}]' >/dev/null
  # The file is written before the trigger is sent, so its arrival is not proof
  # the trigger has landed.
  while [[ "$(calls | grep -c -- '--trigger ai_change')" -eq 0 ]] && ((i < 60)); do
    sleep 0.05
    i=$((i + 1))
  done

  assert_eq '1' "$(calls | grep -c -- '--trigger ai_change')" \
    'a first reading fires ai_change exactly once, not once per poll'
}

test_ai_watch_reports_an_empty_herd_as_zero() {
  local out
  out="$(ai_watch_with '[]')"

  assert_contains "${out}" 'total=0' 'no agents is a real reading, not a missing file'
}

# The state names live in both files and nothing else ties them together, so a
# state added to one and not the other would be counted and never drawn.
test_ai_the_states_the_plugin_paints_are_all_declared_on_the_bar() {
  local plugin_states rc_states
  plugin_states="$(sed -n "s/^states=(\(.*\))$/\1/p" "${PLUGIN_DIR}/ai_agents.sh" \
    | tr -d "'" | tr ' ' '\n' | sort | tr '\n' ' ')"
  rc_states="$(sed -n "s/^for state in \(.*\); do$/\1/p" \
    "${REPO_ROOT}/sketchybar/.config/sketchybar/sketchybarrc" \
    | tr -d "'" | tr ' ' '\n' | sort | tr '\n' ' ')"

  assert_eq "${plugin_states}" "${rc_states}" \
    'ai_agents.sh and sketchybarrc declare the same set of states'
}

# CONTRIB_MAX_AGE and update_freq live in different files and only a comment
# ties them. Raise the age past twice the timer and a contributor that died
# sits on the bar for a whole repaint after it should have gone, which is the
# one thing the heartbeat exists to prevent.
test_ai_the_driver_repaints_before_a_contributor_can_expire() {
  local plugin rc max_age freq
  plugin="${PLUGIN_DIR}/ai_agents.sh"
  rc="${REPO_ROOT}/sketchybar/.config/sketchybar/sketchybarrc"
  max_age="$(sed -n 's/^CONTRIB_MAX_AGE=\([0-9]*\)$/\1/p' "${plugin}")"
  # Scoped to the ai_driver block, because three items carry an update_freq
  # and the other two answer to nothing in ai_agents.sh.
  freq="$(sed -n '/--add item ai_driver/,/script=/ {
    s/^ *update_freq=\([0-9]*\).*$/\1/p
  }' "${rc}")"

  # Each anchor is checked for itself, so a renamed line fails saying so rather
  # than leaving an empty operand to read as line zero.
  if [[ -z "${max_age}" || -z "${freq}" ]]; then
    fail "an anchor moved: CONTRIB_MAX_AGE=[${max_age}] update_freq=[${freq}]"
    return
  fi
  if [[ "$((freq * 2))" -ne "${max_age}" ]]; then
    fail "update_freq ${freq} is not half CONTRIB_MAX_AGE ${max_age}"
  fi
}

# Reads one `gaps.<key>` integer out of aerospace.toml. Shared by the geometry
# test below so that six near-identical sed patterns cannot drift apart.
aerospace_gap() {
  sed -n "s/^gaps\.$2[[:space:]]*=[[:space:]]*\([0-9]*\).*/\1/p" "$1"
}

# The gap geometry spans two packages: JankyBorders' `width=` and the six gap
# values in aerospace.toml, against `height=` here. aerospace.toml states the
# rule in prose and concedes nothing derives one from the other, so this is the
# gate. It lives in this suite because this is the one that already reads
# sketchybarrc. A drift shows up as a strip of desktop above the windows or as
# overlapping borders between them, never as an error.
test_aerospace_gaps_match_the_border_width_and_bar_height() {
  local toml="${REPO_ROOT}/aerospace/.config/aerospace/aerospace.toml"
  local rc="${REPO_ROOT}/sketchybar/.config/sketchybar/sketchybarrc"
  local width height top_builtin top_external drift
  local inner_h inner_v outer_l outer_b outer_r

  width="$(sed -n "s/^[[:space:]]*'exec-and-forget borders .*width=\([0-9.]*\).*/\1/p" "${toml}")"
  height="$(sed -n 's/^[[:space:]]*height=\([0-9]*\).*/\1/p' "${rc}" | head -1)"
  inner_h="$(aerospace_gap "${toml}" 'inner\.horizontal')"
  inner_v="$(aerospace_gap "${toml}" 'inner\.vertical')"
  outer_l="$(aerospace_gap "${toml}" 'outer\.left')"
  outer_b="$(aerospace_gap "${toml}" 'outer\.bottom')"
  outer_r="$(aerospace_gap "${toml}" 'outer\.right')"
  top_builtin="$(sed -n 's/^gaps\.outer\.top.*built-in"[[:space:]]*=[[:space:]]*\([0-9]*\).*/\1/p' "${toml}")"
  top_external="$(sed -n 's/^gaps\.outer\.top.*},[[:space:]]*\([0-9]*\).*/\1/p' "${toml}")"

  # An empty operand would read as zero and quietly satisfy the arithmetic, and
  # a pattern that matched prose as well as the setting yields two lines, which
  # awk truncates to the first. Both have to fail loudly instead.
  local anchor
  for anchor in width height inner_h inner_v outer_l outer_b outer_r \
    top_builtin top_external; do
    if [[ ! "${!anchor}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      fail "anchor ${anchor} did not parse to one number: [${!anchor}]"
      return
    fi
  done

  drift="$(awk -v w="${width}" -v h="${height}" -v ih="${inner_h}" \
    -v iv="${inner_v}" -v ol="${outer_l}" -v ob="${outer_b}" \
    -v orr="${outer_r}" -v tb="${top_builtin}" -v te="${top_external}" 'BEGIN {
      half = w / 2
      if (ih != w) printf "inner.horizontal %s is not width %s; ", ih, w
      if (iv != w) printf "inner.vertical %s is not width %s; ", iv, w
      if (ol != half) printf "outer.left %s is not half-width %s; ", ol, half
      if (ob != half) printf "outer.bottom %s is not half-width %s; ", ob, half
      if (orr != half) printf "outer.right %s is not half-width %s; ", orr, half
      if (tb != half) printf "built-in top %s is not half-width %s; ", tb, half
      if (te != h + half) printf "external top %s is not bar %s plus half-width %s; ", te, h, half
    }')"
  if [[ -n "${drift}" ]]; then
    fail "gap geometry drifted: ${drift}"
  fi
}

# Defined in harness.sh, called here so compgen sees this suite's tests.
main "$@"
