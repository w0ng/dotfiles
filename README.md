# dotfiles

Personal macOS dotfiles (Apple Silicon), provisioned by `bootstrap.sh`. Almost
every top-level directory is a [GNU stow](https://www.gnu.org/software/stow/)
package whose contents mirror `$HOME`, so `bat/.config/bat/config` symlinks to
`~/.config/bat/config`. Editing a stowed file edits the live config, because it
is a symlink back into this repo.

## Install

No prerequisites. `bootstrap.sh` installs Homebrew itself if it is missing, and
runs from wherever you clone it.

```sh
git clone https://github.com/w0ng/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh
```

The first run asks whether this is a personal or work machine and remembers the
answer in `~/.config/dotfiles/profile`. It will not guess. With no terminal to
ask at, it stops and tells you to pass `--profile`.

Expect a few prompts on a fresh machine. Homebrew's installer wants confirmation
and a password, adding Homebrew's zsh to `/etc/shells` needs sudo, and a couple
of casks ship as `.pkg` installers. Everything after that is unattended.

```sh
bash bootstrap.sh --profile=personal  # or work; skips the question
bash bootstrap.sh --list              # show which modules are enabled
bash bootstrap.sh --dry-run           # print what would happen, change nothing
bash bootstrap.sh --no-update         # skip `brew update` (faster re-runs)
bash bootstrap.sh <module>            # run just this module, ignoring MODULES
```

Every module is idempotent, so a second run does nothing but report.

## Updating

`bootstrap.sh` installs what is missing; it never upgrades what is already
there. Updating is deliberately a separate step, one command per manager.

Start with the repo itself. Every stowed file is a symlink back into it, so a
pull updates the live configs immediately. The re-run then picks up any package
or stow target the pull introduced:

```sh
cd ~/dotfiles && git pull && bash bootstrap.sh
```

| What | Command |
| --- | --- |
| Homebrew | `brew update && brew upgrade`, then `brew upgrade --cask --greedy` |
| npm language servers | `npm update -g` |
| zsh plugins | `antidote update` |
| Rust | `rustup update` |
| tmux plugins | In tmux: `C-a U` updates, `C-a I` installs, `C-a M-u` removes |
| Neovim | In nvim: `:lua vim.pack.update()`, then `:TSUpdate` for the parsers |
| sketchybar icon map | Manual, and rarely worth it. See [below](#the-sketchybar-app-font) |
| Housekeeping | `brew autoremove`, `brew cleanup`, `brew doctor` |

- tmux plugins do not install themselves. Bootstrap installs tpm, but tpm only
  sources the plugins already cloned under `~/.config/tmux/plugins`, so a fresh
  machine needs `C-a I` once.
- Adding a plugin to `.zsh_plugins.txt` needs no separate step. antidote
  rebuilds the bundle when that file is newer, so the next shell picks it up.
- `mod_windowmanager` runs sketchybar as a brew service, so a config change
  needs `brew services restart sketchybar`. `killall sketchybar` will not do
  it, because the LaunchAgent carries KeepAlive and respawns the bar it just
  killed.

### What `--greedy` is for

Most casks here declare `auto_updates true` and ship their own updater, and
`brew upgrade` deliberately leaves those alone rather than overwrite what the
app updates for itself. Brew then tracks those casks without ever upgrading
them, which is the "installed once, never updated" state this repo exists to
avoid. `--greedy` re-syncs brew with what is on disk. Running it occasionally is
enough.

### Self-updaters shadow Homebrew

Several of these tools can also update themselves, and some install into
`~/.local/bin`, which `.zshenv` puts ahead of `/opt/homebrew/bin`. The shell
then runs the self-installed copy, while `brew upgrade` goes on updating a
binary you are not running. `uv self update` and Codex's standalone installer
both do exactly this. Homebrew owns both, so let `brew upgrade` handle them and
leave their own updaters alone. To check, run `command -v uv`: anything other
than `/opt/homebrew/bin/uv` is the self-installed copy.

## How it works

### Personal and work machines

A work machine usually has its own device management installing and updating
browsers, chat clients and a set of CLI tools. Homebrew's copy would either
compete with the managed copy's update channel or sit earlier on `PATH` and
shadow it with a different version, so `personal_cask` and `personal_formula`
declare those instead. They install on a personal machine, skip on a work one,
and remove a brew copy an earlier run left behind. `node`, `git` and `tmux` are
deliberately exempt, each for a reason the script gives beside its declaration.

### Machine-local settings

Nothing employer-specific is tracked here. What a work machine needs comes from
a separate private repo stowed on top of this one, through hooks this repo reads
but never ships:

| Path | Reach and contents |
| --- | --- |
| `~/.config/zsh/.zshenv.local` | Every zsh, login or not. Anything a language server or an agent has to inherit |
| `~/.config/zsh/.zshrc.local` | Interactive zsh only. An alias, an export, a tool's `eval` init |
| `~/.config/zsh/functions/` | Interactive zsh, autoloaded on first call. Anything that has to run in the calling shell, such as a picker that `cd`s |
| `~/.config/aerospace/browser.local` | Aerospace, at keypress. One line: the app `alt-shift-b` opens |
| `~/.config/nvim/lua/local.lua` | nvim. Extra project roots and vendored tool paths |

Every config that reads one skips it when absent, so this repo works without any
of them, and an overlay can supply only the ones it needs. The split between the
first two is reach, not preference: shells with no prompt read `.zshenv.local`,
and only shells that have one read `.zshrc.local`. A work-profile run ends by
checking for these hooks, plus the `~/.claude` and `~/.config/git` files it
expects an overlay, or bootstrap itself, to write. `functions/` is the one it
leaves out, because a directory the overlay stows into is not a single file
worth checking for.

Put a setting in one of these rather than inline. `.zshrc` is a symlink into
this repo, so an installer that appends to it writes employer settings straight
into a public repo. Four separate tools have now done exactly that.

### Modules

Each module is a `mod_*` function in `bootstrap.sh`, run in the order listed in
`MODULES`. That ordering is a dependency order, not a preference: `core`
installs stow before anything is stowed, `runtimes` installs node before
`neovim` installs npm language servers, and `zsh` runs last because `.zshrc`
initialises most of the tools above it. `bash bootstrap.sh --list` prints the
enabled ones, and the `mod_*` functions themselves are the package list.
`macos/` is the exception to the stow layout: it holds a script bootstrap runs,
rather than config it links.

Two things bootstrap cannot finish on its own:

- **Caps Lock to Control.** Writing the `modifiermapping` default does not take
  effect, so set it by hand in System Settings > Keyboard > Keyboard Shortcuts >
  Modifier Keys.
- **The git maintenance repo list.** On a work machine `mod_gittools` creates an
  empty `[maintenance]` section in `~/.config/git/config.local`, because which
  repos to register is employer-specific. The run ends by saying so.

## Tests

```sh
bash tests/bootstrap_test.sh   # module wiring, stow, and the package pairing
bash tests/sketchybar_test.sh  # the AeroSpace bar driver
```

Pure bash, no framework, and nothing either does touches the real machine. Each
file's header explains how it stays isolated.

## Agent skills

The `claude` package carries three skills under `claude/.claude/skills/`.
`mod_agents` stows them with the rest of the package, so they reach every repo
on a personal machine and none on a work one.

Two are vendored under `pstack-skills/`, copied from Cursor's MIT-licensed
marketplace: `unslop` strips AI tells from prose, `deslop` strips them from
code. That package's own README covers provenance, why they are copies rather
than an installed plugin, and how to diff one against upstream.

`noslop/` is local rather than vendored, and runs both halves in order:
`deslop` over the code, then the `unslop` rules over the prose. The order
matters. The first pass decides which comments survive, and the second fixes
how they read. Only `/noslop` reaches it, because the skill sets
`disable-model-invocation: true`, so an agent never starts a rewrite of its own
work unasked.

## The sketchybar app font

The glyph beside the focused app's name comes from
[kvndrsslr/sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font)
(CC0-1.0), which arrives in two halves. The font is the
`font-sketchybar-app-font` cask, declared in `mod_windowmanager` and upgraded by
`brew upgrade --cask --greedy` with everything else. Nothing packages the map
from app name to ligature, so the sketchybar package vendors it under
`sketchybar/.config/sketchybar/helpers/`, and `plugins/front_app.sh` sources it
to turn `Ghostty` into `:ghostty: Ghostty`.

The font half cannot be stowed. CoreText ignores a symlink in
`~/Library/Fonts`, so a stowed `.ttf` registers as no font at all and every
ligature renders as its literal `:name:` text. The cask moves a real file into
place, which is the only form macOS reads.

That directory's own README covers provenance, the pinned version, how to
refresh the map, and where the per-app colours in `icon_colors.sh` came from.
