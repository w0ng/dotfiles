#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

# Set the timezone
timedatectl set-timezone 'Australia/Sydney'
sed -i 's/^;\?date.timezone =.*/date.timezone = "Australia\/Sydney"/' \
    /etc/php/7.0/fpm/php.ini \
    /etc/php/7.0/cli/php.ini

# Configure Xdebug
[ ! -d "/vagrant/tmp" ] && mkdir -p "/vagrant/tmp"
cat <<'EOF' >> /etc/php/7.0/mods-available/xdebug.ini
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.cli_color = 1
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
xdebug.profiler_enable_trigger = 1
xdebug.profiler_output_dir = /vagrant/tmp
EOF

# Restart PHP
service php7.0-fpm restart

# Use vi editing mode for readline and editline libraries.
cat <<'EOF' | sudo -u vagrant tee /home/vagrant/.inputrc
$include /etc/inputrc
set editing-mode vi
set completion-ignore-case On

$if mode=vi
  set keymap vi-command
  #
  set keymap vi-insert
  "\C-a": beginning-of-line
  "\C-e": end-of-line
  "\C-l": clear-screen
  "\C-n": history-search-forward
  "\C-p": history-search-backward
$endif
EOF

cat <<'EOF' | sudo -u vagrant tee /home/vagrant/.editrc
bind -v
bind "^A" ed-move-to-beg
bind "^E" ed-move-to-end
bind "^L" ed-clear-screen
bind "^N" ed-search-next-history
bind "^P" ed-search-prev-history
EOF
