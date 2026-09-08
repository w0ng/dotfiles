#!/usr/bin/env bash
#
# macOS defaults. Run by the `macos` module in bootstrap.sh, first, before
# anything is installed. Idempotent, because `defaults write` just sets the
# value.
#
# Two rules for what goes in here:
#
# 1. Prefer the key System Settings itself writes, so the change shows up in
#    the UI rather than silently overriding it. Key repeat, alert volume,
#    tap-to-click and Dock auto-hide all work that way.
#    The animation keys are hidden preferences with no UI; they don't conflict
#    with anything, they just have no pane.
#
# 2. Every key must appear as a string in the binary that reads it, whether
#    Dock, Finder, Mail, or the dyld shared cache for AppKit. A key that is
#    absent is dead, and `defaults write` accepts it in silence. Four keys that
#    circulate in older gist-style configs are already gone:
#    expose-animation-duration,
#    both Mail animation keys, and NSToolbarFullScreenAnimationDuration.
#    Re-check after a major macOS update (last checked on 26.6.2):
#      strings -a /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock | grep -x <key>
#
# Not settable from here, because com.apple.universalaccess reduceMotion is
# TCC-protected and does not write from a terminal without Full Disk Access;
# System Settings > Accessibility > Display > Reduce Motion is the way to be
# sure it's on.
#
# `defaults read <domain> <key>` shows what's set; `defaults delete` reverts.

set -u

# ── Animations: as few as possible ───────────────────────────────────────────

# Reduce Motion covers the most ground. Space switch, Mission Control and
# app-open become fades. The universalaccess write usually fails (TCC); the
# Accessibility key does write and is what the framework checks (23 refs).
defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null || true
defaults write com.apple.Accessibility ReduceMotionEnabled -int 1

# Window open/close, focus ring, resize (0 is ignored; 0.001 is the floor)
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
defaults write -g NSUseAnimatedFocusRing -bool false
defaults write -g NSWindowResizeTime -float 0.001

# Smooth scrolling, Finder column browser, Versions browser
defaults write -g NSScrollAnimationEnabled -bool false
defaults write -g NSBrowserColumnAnimationSpeedMultiplier -float 0
defaults write -g NSDocumentRevisionsWindowTransformAnimation -bool false

# Quick Look close (open still animates), Finder
defaults write -g QLPanelAnimationDuration -int 0
defaults write com.apple.finder DisableAllAnimations -bool true

# Spring-loaded folders: open immediately when hovering a drag
defaults write -g com.apple.springing.delay -float 0

# ── Dock ─────────────────────────────────────────────────────────────────────

# Auto-hide (System Settings > Desktop & Dock), made instant: no delay before
# it appears, no slide.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

# No bounce when launching; scale (not genie) when minimising, the cheapest
# of the three effects and a real System Settings option.
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock mineffect -string scale

# Hot-corner / edge space switching: no hover delay
defaults write com.apple.dock workspaces-edge-delay -float 0

# ── Windows ──────────────────────────────────────────────────────────────────

# Drag a window from anywhere in it with Control-Command, instead of hunting for
# the title bar. A hidden preference, since no System Settings pane references
# it (all of /System/Library/ExtensionKit/Extensions was searched), so this is
# the only way to set it. Reaches apps as they launch, so restart them or log
# out.
defaults write -g NSWindowShouldDragOnGesture -bool true

# System Settings > Desktop & Dock > "Displays have separate Spaces", off. One
# Space stretches across every display, so a window can straddle two screens and
# the menu bar is not pinned per-display.
#
# The name is inverted: spans-displays true IS the toggle being off. Unlike the
# rest of this file it needs a full logout rather than the killall below,
# because the window server reads it once at login (the Dock calls it
# spacesSpansDisplays).
# It also disables the macOS window tiling that Desktop & Dock offers, which
# depends on separate Spaces.
defaults write com.apple.spaces spans-displays -bool true

# ── Keyboard ─────────────────────────────────────────────────────────────────

# System Settings > Keyboard. Key repeat: the slider's "Fast" is 2 (units are
# ~15 ms, so 30 ms between repeats). Delay until repeat: one notch left of
# "Short". The slider positions are 120 94 68 35 25 15, Long to Short.
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 25

# Fast repeat is useless while press-and-hold pops the accent picker instead
# of repeating the letter. Off.
defaults write -g ApplePressAndHoldEnabled -bool false

# Caps Lock -> Control is set by hand in System Settings > Keyboard > Keyboard
# Shortcuts > Modifier Keys. Writing the modifiermapping default the pane uses
# did not take effect, and the pane is a one-time click.

# ── Sound ────────────────────────────────────────────────────────────────────

# System Settings > Sound: alert volume 0%, no UI sound feedback (the
# volume-key beep). Apps read this at launch; running ones need a restart.
defaults write -g com.apple.sound.beep.volume -float 0
defaults write -g com.apple.sound.beep.feedback -int 0

# ── Trackpad ─────────────────────────────────────────────────────────────────

# System Settings > Trackpad > Tap to click. Three places: the built-in
# trackpad, a Bluetooth one, and the global tapBehavior the pane reads.
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
defaults write -g com.apple.mouse.tapBehavior -int 1

# ── Mouse ────────────────────────────────────────────────────────────────────

# System Settings > Mouse > Pointer acceleration off. This is the key the
# Sonoma+ toggle writes; it supersedes the old `scaling -1` hack.
defaults write -g com.apple.mouse.linear -bool true

# ── Finder ───────────────────────────────────────────────────────────────────

# Show ~/Library
chflags nohidden ~/Library
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

# ── Apply ────────────────────────────────────────────────────────────────────

# Dock and Finder re-read their domains on restart; cfprefsd flushes the rest.
# Keyboard, sound and the modifier remap reach new apps now and everything
# after the next login.
killall Dock Finder SystemUIServer cfprefsd 2>/dev/null || true
