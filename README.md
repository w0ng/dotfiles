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

## Modules

Each module is a `mod_*` function in `bootstrap.sh`, run in the order listed
in `MODULES`. That ordering is a dependency order, not a preference: `core`
installs stow before anything is stowed, `runtimes` installs node before
`neovim` installs npm language servers, and `zsh` runs last because `.zshrc`
initialises most of the tools above it.

| Module | What it does |
| --- | --- |
| `macos` | Runs `macos/defaults.bash` — Dock, Finder, keyboard, trackpad. Not a stow package. Caps Lock → Control isn't scripted (the API doesn't take effect); set it in System Settings > Keyboard > Modifier Keys. |
| `apps` | 20 desktop apps, 14 of them personal-only. |
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
