# dotfiles

Personal macOS dotfiles (Apple Silicon), provisioned end-to-end by `bootstrap.sh`.
Almost every top-level directory is a [GNU stow](https://www.gnu.org/software/stow/)
package whose contents mirror `$HOME` — `zsh/.zshenv` symlinks to `~/.zshenv`,
`bat/.config/bat/config` to `~/.config/bat/config`, and so on.
Editing a stowed file edits the live config directly, since it's a symlink
back into this repo. (`macos/` is the exception: it holds a script that gets
run, not stowed.)

## Getting started

No prerequisites — `bootstrap.sh` installs Homebrew itself if it's missing.

```sh
git clone https://github.com/w0ng/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
bash bootstrap.sh
```

The first run asks whether this is a **personal** or **work** machine and
remembers the answer in `~/.config/dotfiles/profile`. It will not guess: with
no terminal to ask at, it stops and tells you to pass `--profile`.

Expect to answer a few prompts on a fresh machine — Homebrew's installer wants
confirmation and a password, adding Homebrew's zsh to `/etc/shells` needs
sudo, and two casks ship as `.pkg` installers. Everything after that is
unattended, and re-runs are silent.

```sh
bash bootstrap.sh --profile=personal  # or work; skips the question
bash bootstrap.sh --list              # show which modules are enabled
bash bootstrap.sh --dry-run           # print what would happen, change nothing
bash bootstrap.sh --no-update         # skip `brew update` (faster re-runs)
bash bootstrap.sh <module>            # run just this module, ignoring MODULES
```

Everything is idempotent — a second run does nothing but report.

## Personal and work machines

A work machine usually has its own device management installing and updating
browsers, chat clients and a set of CLI tools. Homebrew's copy would either
fight that or silently shadow it with a different version, so those are
declared with `personal_cask` and `personal_formula`: installed on a personal
machine, skipped on a work one, and a brew copy left by an earlier run gets
removed.

Three tools are deliberately exempt, and the reasons sit beside them in the
script — `node`, because a managed node's global module directory is typically
root-owned and `npm install -g` cannot write to it; `git`, because a wrapper
that delegates to whichever `git` is on `PATH` needs Homebrew's to be there;
and `tmux`, because the `tpm` formula depends on it, so skipping it would
install tmux as a dependency and remove it again on the next run.

## Machine-local settings

Nothing employer-specific is tracked here. What a work machine needs comes from
a separate private repo stowed on top of this one, through four hooks this repo
reads but never ships:

| Path | Reach | Holds |
| --- | --- | --- |
| `~/.config/zsh/.zshenv.local` | every zsh, login or not | Anything a language server or an agent has to inherit. Sourced before `PATH` is assembled, so appending to `user_path_dirs` gets the same existence check and the same `.zprofile` re-assert as the rest |
| `~/.config/zsh/.zshrc.local` | interactive zsh only | An alias, an export, a tool's `eval` init — the three things that cannot be autoloaded |
| `~/.config/zsh/functions/` | interactive zsh, on first call | One file per function, autoloaded. The right home for anything that has to run in the calling shell, such as a picker that `cd`s. A script on `PATH` cannot: it runs in a child process |
| `~/.config/nvim/lua/local.lua` | nvim | Extra project roots and vendored tool paths, read through `pcall(require, 'local')` |

Every one is optional and skipped when absent, so this repo stands on its own,
and an overlay is free to occupy only the ones it needs. The split between the
first two is reach, not preference: `.zshenv.local` is read by shells that have
no prompt, `.zshrc.local` only by ones that do.

Put a setting in one of these rather than inline. `.zshrc` is a symlink into
this repo, so an installer that appends to it writes employer settings straight
into a public package — which four separate tools have now done.

## Modules

Each module is a `mod_*` function in `bootstrap.sh`, run in the order listed
in `MODULES`. That ordering is a dependency order, not a preference: `core`
installs stow before anything is stowed, `runtimes` installs node before
`neovim` installs npm language servers, and `zsh` runs last because `.zshrc`
initialises most of the tools above it.

| Module | What it does |
| --- | --- |
| `macos` | Runs `macos/defaults.bash` — Dock, Finder, keyboard, trackpad. Not a stow package. Caps Lock → Control isn't scripted (the API doesn't take effect); set it in System Settings > Keyboard > Modifier Keys. |
| `apps` | 22 desktop apps, 16 of them personal-only. |
| `core` | `stow`, the prerequisite every other module needs. |
| `cli` | bat, btop, eza, fd, ffmpeg, fzf, jq, ripgrep, shellcheck, vivid, zoxide; direnv and uv personal-only. Stows configs for bat, btop, fd, fzf. |
| `gittools` | git, git-delta, hunk; gh and git-lfs personal-only. Stows `git/` and `hunk/`. Under the work profile it also checks for a work commit identity and creates an empty `[maintenance]` section in `~/.config/git/config.local` — which repos to register there is left to be filled in by hand, since the paths are employer-specific, and the run ends by saying so. |
| `terminal` | ghostty and Maple Mono NF CN. Stows `ghostty/`. |
| `atuin` | Shell history. |
| `multiplexer` | tmux, tpm and herdr. Stows `tmux/` and `herdr/`. |
| `runtimes` | node, because the language servers below are npm packages, and a Rust toolchain — rustup is personal-only, but the toolchain step runs on both, since neither source installs a compiler on its own. |
| `neovim` | nvim and Neovide, tree-sitter, the language servers and formatters its config drives (lua-language-server, buf, dprint, shfmt, stylua, five npm servers). Stows `nvim/`, `neovide/`, `dprint/`, `stylua/` and `ideavim/`. |
| `windowmanager` | aerospace, sketchybar, borders — third-party taps, so it also trusts them, which Homebrew 6 requires before it will load a formula from one. Stows `aerospace/` and `sketchybar/`. |
| `agents` | codex; claude-code personal-only. |
| `zsh` | Homebrew's zsh and antidote, and makes it the login shell. Stows `zsh/` — a small `~/.zshenv` that sets `ZDOTDIR`, with `.zshrc`, `.zprofile` and `.zsh_plugins.txt` under `~/.config/zsh/`. `.zshenv` cannot move there: zsh reads it before it knows `ZDOTDIR` exists. |

`bootstrap.sh` is the single source of truth for the package list — read the
`mod_*` functions rather than trusting this table.

## Keeping it updated

`bootstrap.sh` installs what is missing; it never upgrades what is already
there. Updating is deliberately a separate act, one command per manager.

Start with the repo itself. Every stowed file is a symlink back into it, so a
pull updates the live configs the moment it lands, and the re-run picks up any
package or stow target the pull introduced:

```sh
cd ~/repos/dotfiles && git pull && bash bootstrap.sh
```

### Homebrew

```sh
brew update && brew upgrade
brew upgrade --cask --greedy
```

The second line does more than it looks like it should. Twenty-one of the
twenty-six casks here declare `auto_updates true` -- 1Password, Chrome,
Firefox, Docker, Spotify and most of the rest ship their own updaters -- and
`brew upgrade` deliberately leaves those alone rather than fight an updater
running behind it. The effect is that brew owns them but never moves them,
which is the "installed once, never updated" state this repo exists to avoid.
`--greedy` re-syncs brew with what is actually on disk; occasionally is enough.

### npm language servers

```sh
npm update -g
```

### zsh plugins

```sh
antidote update
```

Updates antidote and every cloned bundle. The static `.zsh_plugins.zsh` does
not need regenerating afterwards -- it only sources files out of the clone
directories, so refreshed repos are picked up as they are. Regeneration is
driven by mtime, and happens on the next shell after `.zsh_plugins.txt` is
edited.

### tmux plugins

Inside tmux, with the prefix bound to `C-a`: `C-a U` updates, `C-a I`
installs, `C-a M-u` removes. tpm is the one thing on a fresh machine that does
not install itself -- everything else here does.

### Neovim

Inside nvim, `:lua vim.pack.update()` for the plugins, which Neovim's native
`vim.pack` manages rather than a plugin manager, and `:TSUpdate` for the
treesitter parsers.

### Rust

```sh
rustup update
```

### Housekeeping

```sh
brew autoremove   # dependencies nothing needs any more
brew cleanup      # old versions and stale downloads
brew doctor       # broken links, unlinked kegs, deprecated taps
```

### Self-updaters shadow Homebrew

Several of these tools can also update themselves, and some install into
`~/.local/bin` -- which `.zshenv` puts *ahead* of `/opt/homebrew/bin`. When
that happens the self-installed copy silently wins, and `brew upgrade` goes on
diligently updating a binary you are not running. `uv self update` and Codex's
standalone installer both do exactly this.

Homebrew owns both, so let `brew upgrade` handle them and leave their own
updaters alone. `command -v uv` answering anything other than
`/opt/homebrew/bin/uv` is the tell.

## Tests

```sh
bash tests/bootstrap_test.sh
```

Pure bash, no framework — a dependency needed to run the tests would defeat
the point. It sources `bootstrap.sh` rather than executing it, points
`DOTFILES_DIR` and `STOW_TARGET` at a scratch directory and stubs brew, stow,
npm and git, so nothing touches the real machine.

## References

- [Managing dotfiles with GNU Stow](https://venthur.de/2021-12-19-managing-dotfiles-with-stow.html)
