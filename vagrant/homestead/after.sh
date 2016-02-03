#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

# Set the timezone
timedatectl set-timezone 'Australia/Sydney'
sed -i "s/^;\?date.timezone =.*/date.timezone = \"Australia\/Sydney\"/" \
    $(find /etc/php -name php.ini)

# Configure Xdebug
[ ! -d "/vagrant/tmp" ] && mkdir -p "/vagrant/tmp"
cat <<EOF >> /etc/php/mods-available/xdebug.ini
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.cli_color = 1
xdebug.show_local_vars = 1
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
xdebug.profiler_enable_trigger = 1
xdebug.profiler_output_dir = /vagrant/tmp
EOF

# Restart PHP
service php7.0-fpm restart

# Update Laravel Installer
sudo -H -u vagrant sh -c 'composer global require laravel/installer'
