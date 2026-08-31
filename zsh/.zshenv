#
# Hyperlinks
#
# Claude Code decides whether to emit OSC 8 by sniffing TERM_PROGRAM/VTE_VERSION,
# neither of which survives some terminal multiplexers over SSH, so it strips
# hyperlinks from its output — status line included. FORCE_HYPERLINK is checked
# before that allowlist, and must be set before claude starts, hence .zshenv
# rather than .zshrc/.zprofile: zsh sources this for every invocation, including
# non-interactive, non-login shells.
#
export FORCE_HYPERLINK=1
