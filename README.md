# dotfiles

Personal macOS dotfiles managed with GNU [`stow`](https://www.gnu.org/software/stow/).
Each top-level directory is a stow "package" whose layout mirrors `$HOME`; running
`stow <package>` symlinks its contents into place.

Sets up a terminal environment (zsh with antidote + starship + atuin, kitty, tmux),
Neovim with LSP, and assorted CLI tooling (ripgrep, fd, fzf, delta, lsd, …).

## Prerequisites

[Homebrew](https://brew.sh) and GNU `stow`:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install stow
```

Clone this repo into `$HOME`:

```sh
git clone https://github.com/w0ng/dotfiles.git ~/dotfiles && cd ~/dotfiles
```

## Install dependencies (macOS)

Everything is available via Homebrew **except antidote**, which must be git-cloned
(see below).

### Shell — zsh + prompt + history

```sh
brew install starship atuin zoxide direnv fzf
```

antidote (the zsh plugin manager) must be cloned to the exact path `~/.zshrc`
expects — do **not** `brew install` it, as Homebrew uses a different path:

```sh
git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.local/share/antidote
```

Plugins listed in `~/.zsh_plugins.txt` clone themselves on the next shell launch.

### CLI tools

```sh
brew install lsd fd ripgrep coreutils jq
```

- `lsd` — `ls` replacement (aliased in `.zshrc`)
- `fd` / `ripgrep` — used by aliases, fzf-tab, and Neovim
- `coreutils` — provides `gdircolors`, which drives `LS_COLORS` theming
- `jq` — parses JSON for the sketchybar `now_playing` item and the Claude Code status line
- Optional: `brew install bat vivid gist` (`vivid` regenerates the `dircolors-*` themes)

### Neovim

Requires **Neovim ≥ 0.12** — the config uses native `vim.pack`, and plugins install
automatically on first `nvim` launch.

```sh
brew install neovim tree-sitter-cli dprint stylua lua-language-server node
```

LSP servers from npm:

```sh
npm install -g vscode-langservers-extracted cssmodules-language-server stylelint-lsp @typescript/native-preview
```

For the GUI, the optional `neovide/` package matches kitty's font and palette,
and adds the macOS ⌘ clipboard keys that kitty would otherwise handle:

```sh
brew install --cask neovide
```

- `tree-sitter-cli` (the `tree-sitter` command — Homebrew's `tree-sitter` formula is library-only) + Xcode Command Line Tools (`xcode-select --install`) compile Treesitter parsers
- `dprint` / `stylua` are the formatters, run via conform.nvim
- Optional: `brew install rust` — only needed if `fff.nvim` can't download a prebuilt binary and has to build it

### Git

```sh
brew install git git-delta
```

`git-delta` is the configured diff pager (`[pager] diff = delta`).

### Tmux

```sh
brew install tmux reattach-to-user-namespace
```

`reattach-to-user-namespace` backs the `pbcopy` clipboard integration in `.tmux.conf`.

### Terminal & fonts

```sh
brew install --cask kitty font-maple-mono-nl-nf-cn
```

`kitty.conf` sets `font_family Maple Mono NL NF CN`, using the Medium face for
normal text and ExtraBold for bold. `neovide/` names the same four faces so the
Neovide GUI renders identically.

### Sketchybar — now playing

```sh
brew install media-control
```

Streams macOS's Now Playing info (via `MediaRemote.framework`) for the sketchybar
`now_playing` item — event-driven, no polling. `jq` (already listed under CLI tools) parses it.

### Claude Code status line

```sh
brew install gh
gh auth login
```

`claude/.claude/statusline.sh` renders two rows. Row 1 is local: context tokens against the
window, session cost (dimmed at `$0.00`, which is what a `--resume`d session shows before its
next turn — Claude Code restores the context window from the transcript but not the accumulated
cost), and the branch name with how long ago it was cut from `master`/`main`. Row 2 appears once
a PR exists: number and review verdict, conflicts, CI pass/fail counts, unresolved review threads
(current vs. stale), and collapses to `merged` once it lands. Each row fits `$COLUMNS`
independently, dropping segments by priority; nothing is right-aligned, since a half-width pane
strands a right-hand group behind an ellipsis.

`git status` can cost seconds in a large repo, so no segment uses it — the branch comes from
reading `.git/HEAD` directly. Caches live under `~/.cache/cc-statusline/`: branch age for 10
minutes, PR state for 90s, the latter refreshed by `statusline-pr.sh`, spawned detached and
lock-guarded so a render never blocks on the network. A `.attempt` marker caps retries at one a
minute so a failing `gh` call doesn't refresh on every message; delete a cache file to force one.

A few segments are off by default and only activate when their environment variable is set —
useful if a repo has a ticket-linked branch convention, a specific CI check that gates merging, or
stacked PRs. Set these somewhere outside this repo rather than in it, since the values are
typically specific to one codebase/employer — `.zshrc` already sources `~/.devenv.zsh` if present,
which is exactly for config like this that shouldn't be public:

| Variable                                               | Effect                                                                                                                                                               |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CC_STATUSLINE_TICKET_RE`                              | Regex with 3 capture groups (`board`, `number`, `rest`) matched against the branch name; shows a ticket chip                                                         |
| `CC_STATUSLINE_TICKET_URL_FMT`                         | `printf`-style URL template with one `%s` for the ticket key, e.g. `https://example.atlassian.net/browse/%s` — the chip links there instead of showing as plain text |
| `CC_STATUSLINE_MAIN_CHECKOUT`                          | Path to a "primary" checkout that should always stay on the default branch; warns when it isn't                                                                      |
| `CC_STATUSLINE_PR_TRAIN`                               | Set to `1` to walk the PR's base/child chain (extra GraphQL calls) and show stack position plus parent staleness                                                     |
| `CC_STATUSLINE_CI_CHECK_RE`                            | Regex matching the name of the CI check that gates merging; enables an "untested" segment before it runs                                                             |
| `CC_STATUSLINE_CI_BOT_RE` + `CC_STATUSLINE_CI_STEP_RE` | Regexes matching a CI bot's PR comment login, and a named `s` capture group for the failing step name — shown instead of a bare pass/fail count                      |

Icons are Nerd Font glyphs. Underlined segments are OSC 8 hyperlinks, which need
`FORCE_HYPERLINK=1` in the environment — Claude Code decides whether to emit them by sniffing
`TERM_PROGRAM`/`VTE_VERSION`, which some terminal multiplexers don't forward over SSH. `zsh/.zshenv`
exports it for the shell; it also needs to be set in `~/.claude/settings.json`'s `env`, which isn't
part of this repo (see below). `CC_STATUSLINE_NO_LINKS=1` disables links; `CC_STATUSLINE_MARGIN`
tunes reserved columns.

This package doesn't include `~/.claude/settings.json` — unlike `commands/` and `skills/`, that
file tends to accumulate machine- and employer-specific permissions, so it's left for each machine
to manage directly. To wire up the status line, add to it:

```json
{
  "env": { "FORCE_HYPERLINK": "1" },
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0,
    "refreshInterval": 60
  }
}
```

### Optional packages

```sh
brew install mysql weechat   # for the mysql/ and weechat/ configs
```

`ideavim/` is consumed by JetBrains IDEs (install the IDE separately). `readline/`
and `editline/` need no extra packages.

## Symlink with stow

From `~/dotfiles`, stow the packages you want, e.g.:

```sh
stow zsh nvim git tmux kitty starship atuin dircolors dprint stylua fd fzf -t ~
```

Config files are now symlinks back into this repo, so you edit them in place:

```sh
nvim ~/.zshrc      # edits ~/dotfiles/zsh/.zshrc
```

After adding a new file to an already-stowed package, re-run `stow -R <package> -t ~`
to pick it up.

## Post-install

Reload the shell, then launch Neovim once to let `vim.pack` install plugins:

```sh
exec zsh
nvim
```

## macOS system defaults

`.macos/defaults.bash` applies personal macOS preferences and `.macos/Library/Fonts/`
holds bundled fonts. Review before running:

```sh
bash ~/dotfiles/.macos/defaults.bash
```

## References

- [Managing dotfiles with GNU Stow](https://venthur.de/2021-12-19-managing-dotfiles-with-stow.html)
