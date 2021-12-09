#!/bin/bash
#
# Custom defaults on macOS Moneterey 12.0.1
# Source: https://github.com/mathiasbynens/dotfiles/blob/main/.macos
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

# Don’t animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Disable Mission Control animations
defaults write com.apple.dock expose-animation-duration -int 0

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -int 0

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -int 0

# Disable send and reply animations in Mail.app
defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true

# Show the ~/Library folder
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library

# Use dark mode for menu and dock, but keep everything else light
# (note: this makes volume/brightness slider values not visible)
#defaults write -g NSRequiresAquaSystemAppearance -bool Yes
