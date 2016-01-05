#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

# Set the timezone
timedatectl set-timezone 'Australia/Sydney'

# Update Laravel Installer
sudo -H -u vagrant sh -c 'composer global require laravel/installer'

# Install Xdebug
apt-get install -y php-xdebug

# Configure Xdebug
cat >> "$(find /etc/php -name xdebug.ini)" <<EOF
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream = 0
xdebug.cli_color = 1
xdebug.show_local_vars = 1
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
xdebug.profiler_enable_trigger = 1
xdebug.profiler_output_dir = /tmp
EOF

# Disable Xdebug by default
sed -ri 's/^(zend_extension=)/;\1/' "$(find /etc/php -name xdebug.ini)"

# Add aliases for common commands
cat > /home/vagrant/.bash_aliases <<EOF
# Load xdebug Zend extension with php command
alias php='php -dzend_extension=xdebug.so'
# PHPUnit needs xdebug for coverage. In this case, just make an alias with php command prefix.
alias phpunit='php $(which phpunit)'

# Shortcuts to common artisan commands (Laravel)
alias pa='php artisan'
alias pat='php artisan tinker'
EOF

chown vagrant:vagrant /home/vagrant/.bash_aliases

# Restart PHP
service php7.0-fpm restart
