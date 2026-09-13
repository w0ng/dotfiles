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
`bootstrap.sh` runs and `tests/` holds the suites below. `alfred/` holds an
Alfred workflow that searches System Settings behind the keyword `s`, and
`mod_alfred` copies it into place rather than symlinking it.

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
| `alfred` | Copies the Alfred workflow again, which a pull cannot update |
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
| `~/.claude/CLAUDE.md` | Coding guides and repo conventions |
| `~/.claude/settings.json` | Permissions, MCP allow and deny lists, plugins |
| `~/.claude/statusline.zsh` | The statusline |

A work-profile run ends by reporting which of these it found, along with
`~/.config/git/config.local` and `~/.config/git/config.work`, which bootstrap
writes itself. `functions/` is the one it leaves out, being a directory rather
than a single file.

Put a machine-local setting in one of these rather than inline. `.zshrc` is a
symlink into this public repo, so an installer that appends to it commits your
settings here. Four installers have now done exactly that.

## Tests

```sh
bash tests/bootstrap_test.sh   # module wiring, stow, and the package pairing
bash tests/update_test.sh      # the update steps and their unattended contract
bash tests/sketchybar_test.sh  # the AeroSpace bar driver
```

Pure bash, no framework, and nothing any of them does touches the real machine.
