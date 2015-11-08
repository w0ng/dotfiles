#!/bin/bash
#
# Custom defaults on OS X Yosemite 10.10.1
# Source: https://github.com/mathiasbynens/dotfiles/blob/master/.osx
# Execute `defaults delete [domain [key]]` to revert changes

# Disable animations, e.g. opening a new window
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

# Reduce window resize time for Cocoa applications (-int 0 doesnt work)
defaults write -g NSWindowResizeTime -float 0.001

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

# Disable system sounds. `sudo nvram -d SystemAudioVolume` to revert.
sudo nvram SystemAudioVolume=%80

# Disable native full screen for mvim (i.e. don't create a new space)
defaults write org.vim.MacVim MMNativeFullScreen 0

# Auto-hide menu bar
# defaults write -g _HIHideMenuBar 1
# TODO: useless until we can remove animation speed/delay.
# Disable menu bar show/hide animation (???)
# Remove auto-hide menu bar delay (???)

# Disable send and reply animations in Mail.app (does not work in El Capitan)
# TODO:
#defaults write com.apple.mail DisableReplyAnimations -bool true
#defaults write com.apple.mail DisableSendAnimations -bool true

# TODO:
# Disable full screen animation: install Linux, because Apple.
# Disable desktop switching animation: pay $25 for TotalSpaces2, because Apple 
# (NOTE: no longer works since SIP was introduced in El Capitan)
