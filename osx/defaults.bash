#!/bin/bash
#
# Custom defaults on OS X El Capitan 10.11.2
# Source: https://github.com/mathiasbynens/dotfiles/blob/master/.osx
# Execute `defaults delete [domain [key]]` to revert changes

# Disable animations, e.g. opening and closing a new window
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

# Disable the over-the-top focus ring animation
defaults write -g NSUseAnimatedFocusRing -bool false

# Reduce window resize time for Cocoa applications (-int 0 doesnt work)
defaults write -g NSWindowResizeTime -float 0.001

# Disable closing Quick Look animations (doesn't work for opening)
defaults write -g QLPanelAnimationDuration -int 0

# Disable window animations and Get Info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Disable Mission Control animations
defaults write com.apple.dock expose-animation-duration -int 0

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -int 0

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -int 0

# Show the ~/Library folder
chflags nohidden ~/Library

# Disable native full screen for mvim (i.e. don't create a new space)
defaults write org.vim.MacVim MMNativeFullScreen 0
