#!/usr/bin/env bash
# Colour per app for the sketchybar-app-font glyphs, keyed by the ligature
# icon_map.sh returns.
#
# Source colors.sh first. Some arms resolve to $FG.
#
# helpers/README.md records where the values came from, and why an app the table
# has no entry for ends up the same colour as the $FG arms.

# shellcheck disable=SC2034 # color_result is read by the caller that sources this
__icon_color() {
  case "$1" in
    :activity_monitor:   ) color_result=0xff52b986 ;;
    :affinity:           ) color_result=0xff8ff461 ;;
    :airport_utility:    ) color_result=0xff1193ff ;;
    :app_store:          ) color_result=0xff4086f3 ;;
    :apple_tv:           ) color_result=0xffa2daed ;;
    :arduino:            ) color_result=0xff13999d ;;
    :audio_midi_setup:   ) color_result=0xffd56d5a ;;
    :automator:          ) color_result=0xff55a0d8 ;;
    :balena_etcher:      ) color_result=0xffa5de37 ;;
    :bluetooth:          ) color_result=0xff058cfc ;;
    :brave_browser:      ) color_result=0xffec622c ;;
    :calculator:         ) color_result=0xfff49616 ;;
    :calendar:           ) color_result=0xffff3c44 ;;
    :chess:              ) color_result=0xffa9835f ;;
    :claude:             ) color_result=0xffd9714f ;;
    :clock:              ) color_result=0xffe8cca7 ;;
    :codex:              ) color_result=0xff758cf7 ;;
    :color_picker:       ) color_result=0xfffc3a2f ;;
    :console:            ) color_result=0xffd6b441 ;;
    :contacts:           ) color_result=0xfffb9e24 ;;
    :dash:               ) color_result=0xffaf73cc ;;
    :dictionary:         ) color_result=0xffe15966 ;;
    :discord:            ) color_result=0xff7981f8 ;;
    :disk_utility:       ) color_result="$FG" ;;
    :docker:             ) color_result=0xff1c90ed ;;
    :face_time:          ) color_result=0xff4dec68 ;;
    :figma:              ) color_result=0xffff763a ;;
    :finder:             ) color_result=0xff00b0ff ;;
    :firefox:            ) color_result=0xfffb3d57 ;;
    :font_book:          ) color_result="$FG" ;;
    :freeform:           ) color_result=0xff029abc ;;
    :games:              ) color_result=0xfffd374a ;;
    :gear:               ) color_result="$FG" ;;
    :ghostty:            ) color_result=0xff677df7 ;;
    :google_chrome:      ) color_result=0xfffabb13 ;;
    :grapher:            ) color_result=0xfffc681b ;;
    :home:               ) color_result=0xfff09010 ;;
    :iina:               ) color_result=0xff0092f8 ;;
    :image_playground:   ) color_result=0xff58a8cf ;;
    :inkscape:           ) color_result=0xff7689af ;;
    :insomnia:           ) color_result=0xff9d72f4 ;;
    :iphone_mirroring:   ) color_result=0xff857df1 ;;
    :iterm:              ) color_result=0xff1ad129 ;;
    :jdownloader:        ) color_result=0xffe9d41a ;;
    :jetbrains_toolbox:  ) color_result=0xfffc3276 ;;
    :journal:            ) color_result=0xff9670f9 ;;
    :keyboard_maestro:   ) color_result=0xffefebdd ;;
    :keynote:            ) color_result=0xff3886f4 ;;
    :magnifier:          ) color_result=0xff9f8718 ;;
    :mail:               ) color_result=0xff52b6f6 ;;
    :maps:               ) color_result=0xff36cf5a ;;
    :mediainfo:          ) color_result=0xff7d7aff ;;
    :messages:           ) color_result=0xff53f16e ;;
    :minecraft:          ) color_result=0xff52a535 ;;
    :music:              ) color_result=0xfffe395d ;;
    :neovide:            ) color_result=0xff63aa44 ;;
    :news:               ) color_result=0xfffe4c6b ;;
    :nord_vpn:           ) color_result=0xff6781ff ;;
    :notes:              ) color_result=0xffffd630 ;;
    :numbers:            ) color_result=0xff68f05a ;;
    :obsidian:           ) color_result=0xffae8eef ;;
    :one_password:       ) color_result=0xff0c90fa ;;
    :openai:             ) color_result="$FG" ;;
    :pages:              ) color_result=0xfffdab29 ;;
    :passwords:          ) color_result=0xfff1ca4c ;;
    :phone:              ) color_result=0xff62fb7c ;;
    :photos:             ) color_result=0xfffc505a ;;
    :plex:               ) color_result=0xffebaf00 ;;
    :podcasts:           ) color_result=0xffaa73d6 ;;
    :postman:            ) color_result=0xffff6c37 ;;
    :preview:            ) color_result=0xff4986ff ;;
    :print_center:       ) color_result=0xff38b869 ;;
    :quicktime:          ) color_result=0xff01b3ff ;;
    :reminders:          ) color_result=0xffe1e9ed ;;
    :safari:             ) color_result=0xff4eaef7 ;;
    :script_editor:      ) color_result="$FG" ;;
    :shortcuts:          ) color_result=0xff9976da ;;
    :siri:               ) color_result=0xff3b8be3 ;;
    :slack:              ) color_result=0xffecb22e ;;
    :spotify:            ) color_result=0xff1ed860 ;;
    :stickies:           ) color_result=0xfff8d52a ;;
    :stocks:             ) color_result=0xff0e95d4 ;;
    :system_information: ) color_result="$FG" ;;
    :telegram:           ) color_result=0xff01aee6 ;;
    :terminal:           ) color_result="$FG" ;;
    :textedit:           ) color_result=0xfff6b2b3 ;;
    :time_machine:       ) color_result=0xff55b8ae ;;
    :tips:               ) color_result=0xfffeb801 ;;
    :todoist:            ) color_result=0xfff25847 ;;
    :weather:            ) color_result=0xff1c89ea ;;
    :whats_app:          ) color_result=0xff03d758 ;;
    :xcode:              ) color_result=0xff0fb1fa ;;
    :yubico:             ) color_result=0xff9aca3c ;;
    :zoom:               ) color_result=0xff4387ff ;;
    *) color_result="" ;;
  esac
}
