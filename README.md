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
there. `update.sh` is the other half: it upgrades and installs nothing.

```sh
bash update.sh              # every step
bash update.sh brew neovim  # only these
bash update.sh --list       # print the steps
bash update.sh --dry-run    # print what would happen, change nothing
bash update.sh --greedy     # also re-sync casks that update themselves
```

It runs unattended, so a launchd job or a cron line can call it. Nothing
prompts, one failing step does not stop the others, and the exit status is
non-zero if any of them failed. Seven steps, in this order:

| Step | What it does |
| --- | --- |
| `repo` | `git pull --ff-only` on this repo, skipped if the checkout has local edits |
| `brew` | `brew update && brew upgrade`, then `autoremove`, `cleanup` and `doctor` |
| `npm` | `npm update -g` over the packages `mod_neovim` declares, and only those |
| `rust` | `rustup update --no-self-update` |
| `tmux` | tpm's `update_plugins all` |
| `neovim` | `vim.pack.update()` in a headless nvim, then the tree-sitter parsers |
| `zsh` | `antidote update --bundles`, then touches `.zsh_plugins.txt` so the bundle rebuilds |

`brew` comes before the five steps that run under it, because it is what
brings the new tmux, neovim, node, rustup and antidote. `repo` comes first,
because a pull can change the config every later step reads; it only reports
what the pull brought, since installing a package the new commits added is
`bootstrap.sh`'s job:

```sh
bash update.sh; bash bootstrap.sh
```

`;` rather than `&&`, because a step failing for its own reasons should not
skip the install of packages a pull brought in.

Two things `update.sh` deliberately leaves alone. Casks that update themselves
need `--greedy`, which can ask for a password and so is not the default. And
tpm updates the plugins already cloned under `~/.config/tmux/plugins` but
installs none, so a fresh machine, or a plugin newly added to `tmux.conf`,
still needs `C-a I` once.

### One manager at a time

The commands behind each step, for when you want to run just one by hand:

| What | Command |
| --- | --- |
| Homebrew | `brew update && brew upgrade`, then `brew upgrade --cask --greedy` |
| npm language servers | `npm update -g <the packages mod_neovim declares>` |
| zsh plugins | `antidote update --bundles` |
| Rust | `rustup update --no-self-update` |
| tmux plugins | In tmux: `C-a U` updates, `C-a I` installs, `C-a M-u` removes |
| Neovim | In nvim: `:lua vim.pack.update()`, then `:TSUpdate` for the parsers |
| sketchybar icon map | Manual, and rarely worth it. See [below](#the-sketchybar-app-font) |
| Housekeeping | `brew autoremove`, `brew cleanup`, `brew doctor` |

- The flags are the point in three of those rows, and `update.sh` passes them
  for the same reasons. A bare `npm update -g` upgrades every global on the
  machine, including the npm inside Homebrew's `node` keg; `antidote update`
  without `--bundles` tries to update antidote itself, which Homebrew owns;
  `rustup update` without `--no-self-update` does the same to rustup.
- Adding a plugin to `.zsh_plugins.txt` needs no separate step. antidote
  rebuilds the bundle when that file is newer, so the next shell picks it up.
- `mod_windowmanager` runs sketchybar as a brew service, so a config change
  needs `brew services restart sketchybar`. `killall sketchybar` will not do
  it, because the LaunchAgent carries KeepAlive and respawns the bar it just
  killed.
- The bar's AI agent counters read herdr, which `mod_multiplexer` installs
  rather than `mod_windowmanager`. `helpers/ai_watch.sh` reads the counts off
  herdr's socket once a second — herdr emits no event when an agent's status
  changes, so a subscription alone misses them — and is started by
  `sketchybarrc`, so restarting the bar restarts it too. With herdr absent the
  watcher exits and the segment stays hidden, which is also what a machine with
  no agents running looks like.

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
bash tests/update_test.sh      # the update steps and their unattended contract
bash tests/sketchybar_test.sh  # the AeroSpace bar driver
```

Pure bash, no framework, and nothing any of them does touches the real machine.
Each file's header explains how it stays isolated.

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
