# App icon helpers

`icon_map.sh` is vendored from
[kvndrsslr/sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font)
(CC0-1.0, see `LICENSE`) at v2.0.86, unmodified. It maps an app name to the
ligature the font draws as that app's glyph, and `plugins/front_app.sh` sources
it to turn `Ghostty` into `:ghostty: Ghostty`.

The font itself is the `font-sketchybar-app-font` cask, declared in
`mod_windowmanager`. Upstream packages the map nowhere, which is why this copy
exists. Move the two together. A map newer than the font names ligatures the
font has no glyph for.

## Refreshing the map

Refresh the map only when an app is missing its icon. Upstream generates it
from its own SVGs and mappings, so take a release rather than rebuilding it.
Set `ver` to the newest release and update the version recorded above in the
same commit, or the pin here stops being true.

```sh
ver=v2.0.86
curl -fsSL -o ~/dotfiles/sketchybar/.config/sketchybar/helpers/icon_map.sh \
  "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/$ver/icon_map.sh"
brew upgrade --cask --greedy font-sketchybar-app-font
sketchybar --reload
```

`git diff` then shows which apps the new map added.

## icon_colors.sh

`icon_colors.sh` is this repo's own, not upstream's. The font carries no `COLR`
or `CPAL` table and the map records only names, so every glyph is a flat
silhouette and an app is whatever single colour the bar paints it. The table
keys on the same ligature `icon_map.sh` returns. Source `colors.sh` before it,
because some arms resolve to `$FG`.

Each value came from the icon in the app's own bundle. Take the largest `.icns`
representation, quantise it to 24 colours, keep the most-used saturated one,
weight towards mid lightness so a dark backplate cannot outweigh the mark drawn
on top of it, then lighten it until it clears 4.5:1 against `$BAR`. The lowest
in the table is 4.52:1. The glyph lands on the bar itself, which `sketchybarrc`
paints `$BLACK`, so it clears 5.79:1 where it is actually drawn.

An icon with no hue at all, such as ChatGPT's or Terminal's, takes `$FG`, and so
does an app the table has no entry for. The two cases look alike on the bar. The
`$FG` arms stay because they record a sampled result rather than the absence of
one.

The entries name the apps installed here, so regenerate the table on a personal
machine only. Sampling a work machine's `/Applications` would commit an
employer's software list to a public repo.
