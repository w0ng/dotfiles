# dotfiles

Personal macOS dotfiles for Apple Silicon, provisioned by `bootstrap.sh`. Almost
every top-level directory is a [GNU stow](https://www.gnu.org/software/stow/)
package whose contents mirror `$HOME`, so `bat/.config/bat/config` symlinks to
`~/.config/bat/config`. Editing a stowed file edits the live config.

## What's in here

The stow packages, which are the configuration this repo tracks:

| Area | Packages |
| --- | --- |
| Shell | `zsh` (antidote, a prompt written in zsh), `atuin` for history |
| Editor | `nvim` (native `vim.pack`), `neovide`, `ideavim`, `stylua`, `dprint` |
| Terminal | `ghostty`, `tmux`, `herdr` |
| Window management | `aerospace`, `sketchybar` |
| Git | `git`, `hunk` |
| Command line | `bat`, `btop`, `fd`, `fzf`, `yazi` |
| Agents | `claude`, the Claude Code config and skills, on personal machines only |

Bootstrap installs more than it configures: the browsers, chat
clients and desktop apps of `mod_apps`, and the CLI tools that need no config of
their own, such as `ripgrep`, `eza`, `jq` and `zoxide`. The `mod_*` functions in
`bootstrap.sh` are the package list, and `bash bootstrap.sh --modules` names
them all.

Not every top-level directory is a package. `macos/` holds a script
`bootstrap.sh` runs and `tests/` holds the suites below. `alfred/` holds Alfred
workflow source, which `mod_alfred` copies into place rather than symlinking.
Each workflow's `info.plist` names the keywords it answers to.

## Install

No prerequisites. `bootstrap.sh` installs Homebrew if it is missing, and runs
from wherever you clone it.

```sh
git clone https://github.com/w0ng/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh
```

The first run asks whether this is a personal or work machine and remembers the
answer in `~/.config/dotfiles/profile`. It will not guess. With no terminal to
ask at, it stops and tells you to pass `--profile`. A work profile skips the
browsers, chat clients and CLI tools a managed machine installs for itself, and
removes a brew copy an earlier run left behind.

Expect a few prompts on a fresh machine. Homebrew's installer wants a password,
adding its zsh to `/etc/shells` needs sudo, and a couple of casks ship as `.pkg`
installers. Everything after that is unattended, and every module is idempotent,
so a second run only reports.

```sh
bash bootstrap.sh --profile=personal  # or work; skips the question
bash bootstrap.sh --list              # the modules this machine runs
bash bootstrap.sh --modules           # every module the script defines
bash bootstrap.sh --dry-run           # print what would happen, change nothing
bash bootstrap.sh --no-update         # skip `brew update`, for faster re-runs
bash bootstrap.sh <module>            # run just this module
```

## Updating

`bootstrap.sh` installs what is missing and never upgrades. `update.sh` is the
other half, and upgrades without installing. It runs unattended, so launchd or
cron can call it. One failing step does not stop the others, and the exit status
is non-zero if any of them failed.

```sh
bash update.sh              # every step
bash update.sh brew neovim  # only these
bash update.sh --list       # print the steps
bash update.sh --dry-run    # print what would happen, change nothing
bash update.sh --greedy     # also re-sync casks that update themselves
```

| Step | What it does |
| --- | --- |
| `repo` | `git pull --ff-only`, skipped if the checkout has local edits |
| `alfred` | Copies the Alfred workflows again, which a pull cannot update |
| `brew` | `brew update && brew upgrade`, then `autoremove`, `cleanup` and `doctor` |
| `npm` | `npm update -g` over the packages `mod_neovim` declares, and only those |
| `rust` | `rustup update --no-self-update` |
| `tmux` | tpm's `update_plugins all`, which installs none |
| `neovim` | `vim.pack.update()` in a headless nvim, then the tree-sitter parsers |
| `zsh` | `antidote update --bundles`, then rebuilds the plugin bundle |

Casks that update themselves are the reason for `--greedy`. `brew upgrade`
leaves them alone rather than overwrite their own updater, so brew's record of
them drifts from what is on disk. `--greedy` re-syncs it, and re-downloads every
one of them, which is why it is a flag rather than the default.

tpm updates the plugins it has already cloned but installs none, so a fresh
machine, or a plugin newly added to `tmux.conf`, needs `C-a I` once. Installing
what new commits added is still bootstrap's job:

```sh
bash update.sh; bash bootstrap.sh
```

`;` rather than `&&`, because a step failing for its own reasons should not skip
installing what the pull brought in.

## Machine-local settings

Nothing employer-specific is tracked here. A private overlay repo stows on top
of this one, through hooks this repo reads but never ships. Every config skips
its hook when absent, so this repo works without any of them.

| Path | Reach and contents |
| --- | --- |
| `~/.config/zsh/.zshenv.local` | Every zsh. PATH entries and env anything, an agent included, has to inherit |
| `~/.config/zsh/.zshrc.local` | Interactive zsh. Aliases, exports, a tool's `eval` init |
| `~/.config/zsh/functions/` | Interactive zsh, autoloaded. Anything that has to run in the calling shell |
| `~/.config/aerospace/browser.local` | The app `alt-shift-b` opens |
| `~/.config/nvim/lua/local.lua` | Extra project roots and vendored formatter paths |
| `~/.config/sketchybar/sketchybarrc.local` | Extra bar items, sourced before the bar's first paint |
| `~/.claude/CLAUDE.md` | Coding guides and repo conventions |
| `~/.claude/settings.json` | Permissions, MCP allow and deny lists, plugins |
| `~/.claude/statusline.zsh` | The statusline |

A work-profile run ends by reporting which of these it found, along with
`~/.config/git/config.local` and `~/.config/git/config.work`, which bootstrap
writes itself. `functions/` is the one it leaves out, being a directory rather
than a single file.

The bar's agent counters take their data through a second hook, a drop
directory rather than a config file. `helpers/ai_watch.py` counts the herdr
running beside the bar. Anything watching a herdr this machine cannot reach
writes what it sees to `~/.cache/sketchybar/ai_agents.d/<name>`, and
`plugins/ai_agents.sh` adds those files to the local counts, so the bar shows
one total.

A contributor writes any of `working=`, `blocked=`, `done=` and `idle=`, one per
line, digits only and under six of them, since a longer value wraps bash's
arithmetic and is read as zero. A name it leaves out counts as zero, and the
total is derived, so writing a `total=` line does nothing. It rewrites the
whole file every cycle, because the plugin reads the mtime as a heartbeat and
stops counting a file last written over a minute ago. A temp file renamed over
the top needs a leading dot, which the plugin's glob skips.

`helpers/ai_watch.py` is not a model for one. It writes the local file, which
no heartbeat checks, so it skips the write while the counts have not moved. A
contributor copying that would freeze its own mtime whenever its herd went
quiet and drop off the bar a minute later, still running. A writer started from
`sketchybarrc.local` also has to stop its previous copy the way this repo's own
watcher does, because a reload re-runs that file and leaves the old one
counting into the same name.

Put a machine-local setting in one of these rather than inline. `.zshrc` is a
symlink into this public repo, so an installer that appends to it commits your
settings here. Four installers have now done exactly that.

## Tests

```sh
bash tests/bootstrap_test.sh   # module wiring, stow, and the package pairing
bash tests/update_test.sh      # the update steps and their unattended contract
bash tests/sketchybar_test.sh  # the AeroSpace bar driver
bash tests/lint_test.sh        # shell, zsh, python and lua style
```

Pure bash, no framework, and nothing any of them does touches the real machine.

`lint_test.sh` is the one exception to "no framework": it shells out to
shellcheck, shfmt, ruff, stylua and zsh, because asking what those tools say is
the whole point of it. It reads repo files and writes nothing, because ruff
runs with `--no-cache` and so leaves no `.ruff_cache/` behind. It skips with a
notice rather than failing when a tool is not installed.
