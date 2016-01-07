#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

# Set the timezone
timedatectl set-timezone 'Australia/Sydney'

# Update Laravel Installer
sudo -H -u vagrant sh -c 'composer global require laravel/installer'

# Add aliases for common commands
cat > /home/vagrant/.bash_aliases <<EOF
# Shortcuts to common artisan commands (Laravel)
alias pa='php artisan'
alias pat='php artisan tinker'
EOF

chown vagrant:vagrant /home/vagrant/.bash_aliases

# Restart PHP
service php7.0-fpm restart
