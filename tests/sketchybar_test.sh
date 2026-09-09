#!/bin/bash
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

# These repeat colors.sh rather than sourcing it, so a wrong edit there fails a
# test instead of changing both sides of the comparison at once.
readonly BAR=0xf01d2021
readonly BG0=0xff282828
readonly FG=0xffebdbb2
readonly GRAY=0xffa89984
readonly GRAY_DARK=0xff7c6f64
readonly YELLOW=0xfffabd2f
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
  chmod +x "${WORK_DIR}/stubs/"*
  export STUB_LOG
}

teardown() {
  [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
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

# An unparseable count must not leave the pill stuck hidden.
test_unreadable_monitor_count_still_draws() {
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

# Defined in harness.sh, called here so compgen sees this suite's tests.
main "$@"
