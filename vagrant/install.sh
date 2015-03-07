#!/usr/bin/env bash
#
# References:
#   https://github.com/fideloper/Vaprobash
#   https://serversforhackers.com/ssl-certs/
#   https://www.linode.com/docs/websites/apache/running-fastcgi-php-fpm-on-debian-7-with-apache
#   https://github.com/w0ng/dotfiles/blob/master/.vimrc

# =============================================================================

echo "--- Adding non-free and Dotdeb repositories ---"

# Non-free
sed -ri "s/^(deb.* main)$/\1 non-free/" /etc/apt/sources.list

# Dotdeb repos, for MySQL 5.6 and PHP 5.6
cat <<EOF >> /etc/apt/sources.list

# Main Dotdeb repository
deb http://packages.dotdeb.org wheezy all
deb-src http://packages.dotdeb.org wheezy all
# PHP 5.6 for Debian 7 "Wheezy"
deb http://packages.dotdeb.org wheezy-php56 all
deb-src http://packages.dotdeb.org wheezy-php56 all
EOF

wget http://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg
rm dotdeb.gpg

# =============================================================================

echo "--- Installing base packages ---"

apt-get update
apt-get upgrade -y
apt-get install -y \
    build-essential \
    curl \
    git-core \
    mlocate \
    nfs-common \
    python-software-properties \
    unzip

# =============================================================================

echo "--- Creating a wildcard self-signed SSL Certificate ---"

SSL_DIR="/etc/ssl/xip.io"
DOMAIN="*.xip.io"
PASSPHRASE=""
SUBJ="
C=AU
ST=New South Wales
O=
localityName=Sydney
commonName=$DOMAIN
organizationalUnitName=
emailAddress=
"

[[ ! -d "$SSL_DIR" ]] && mkdir -p "$SSL_DIR"

# Generate private key, csr and certificate
openssl genrsa \
    -out "$SSL_DIR/xip.io.key" 2048

openssl req \
    -new \
    -subj "$(echo -n "$SUBJ" | tr "\n" "/")" \
    -key "$SSL_DIR/xip.io.key" \
    -out "$SSL_DIR/xip.io.csr" \
    -passin pass:$PASSPHRASE

openssl x509 \
    -req \
    -days 365 \
    -in "$SSL_DIR/xip.io.csr" \
    -signkey "$SSL_DIR/xip.io.key" \
    -out "$SSL_DIR/xip.io.crt"

# =============================================================================

# Set mysql root user password to 'root'
debconf-set-selections <<< \
    'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< \
    'mysql-server mysql-server/root_password_again password root'

echo "--- Installing Apache, MySQL and PHP ---"

# Use native driver to prevent minor version mismatch warning with mysql 5.6:
# php5-mysqlnd instead of php5-mysql
# FIXME: add php5-xdebug when the 5.6 package is released
apt-get install -y \
    apache2 \
    apache2-mpm-worker \
    libapache2-mod-fastcgi \
    mysql-server-5.6 \
    php5-cli \
    php5-fpm \
    php5-curl \
    php5-gd \
    php5-gmp \
    php5-imagick \
    php5-intl \
    php5-ldap \
    php5-mcrypt \
    php5-memcached \
    php5-mysqlnd

# =============================================================================

echo "--- Configuring PHP ---"

# Add vagrant user to group used for PHP5-FPM
usermod -a -G www-data vagrant

# Display all errors
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" \
    /etc/php5/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" \
    /etc/php5/fpm/php.ini

# Set timezone
sed -i "s/^;\?date.timezone =.*/date.timezone = \"Australia\/Sydney\"/" \
    /etc/php5/fpm/php.ini
sed -i "s/^;\?date.timezone =.*/date.timezone = \"Australia\/Sydney\"/" \
    /etc/php5/cli/php.ini

# Xdebug: enable extension, do not limit output, enable triggered profiler
# FIXME: uncomment when php5-xdebug for php 5.6 is available
#[[ ! -d "/vagrant/tmp" ]] && mkdir -p "/vagrant/tmp"
#cat > "$(find /etc/php5 -name xdebug.ini)" << EOF
#zend_extension=$(find /usr/lib/php5 -name xdebug.so)
#xdebug.remote_enable = 1
#xdebug.remote_connect_back = 1
#xdebug.remote_port = 9000
#xdebug.scream = 0
#xdebug.cli_color = 1
#xdebug.show_local_vars = 1
#xdebug.var_display_max_depth = -1
#xdebug.var_display_max_children = -1
#xdebug.var_display_max_data = -1
#xdebug.profiler_enable_trigger = 1
#xdebug.profiler_output_dir = /vagrant/tmp
#EOF

service php5-fpm restart

echo "PHP configured."

# =============================================================================

echo "--- Configuring MySQL ---"

sed -i '/\[mysqld\]/a sql_mode = "STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION"\n' \
    /etc/mysql/my.cnf

echo "MySQL set to strict mode."

# =============================================================================

echo "--- Configuring Apache ---"

SERVER_NAME="$1"
SERVER_ALIAS="$2"
DOC_ROOT="$3"
CERT_PATH="/etc/ssl/xip.io"
CERT_NAME="xip.io"

[[ ! -d "$DOC_ROOT" ]] && mkdir -p "$DOC_ROOT"

# Create a vhost using arguments supplied by VagrantFile
[[ ! -f "${DOC_ROOT}/${SERVER_NAME}.conf" ]] && \
    cat <<EOF > /etc/apache2/sites-available/${SERVER_NAME}.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName ${SERVER_NAME}
    ServerAlias ${SERVER_ALIAS}
    DocumentRoot ${DOC_ROOT}
    <Directory ${DOC_ROOT}>
        Options +Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${SERVER_NAME}-error.log
    LogLevel warn
    CustomLog \${APACHE_LOG_DIR}/${SERVER_NAME}-access.log combined
</VirtualHost>
EOF

# Create an SSL vhost using the xip.io cert created earlier
[[ -d "${CERT_PATH}" ]] && \
    cat <<EOF >> /etc/apache2/sites-available/${SERVER_NAME}.conf
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName ${SERVER_NAME}
    ServerAlias ${SERVER_ALIAS}
    DocumentRoot ${DOC_ROOT}
    <Directory ${DOC_ROOT}>
        Options +Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${SERVER_NAME}-error.log
    LogLevel warn
    CustomLog \${APACHE_LOG_DIR}/${SERVER_NAME}-access.log combined
    SSLEngine on
    SSLCertificateFile ${CERT_PATH}/${CERT_NAME}.crt
    SSLCertificateKeyFile ${CERT_PATH}/${CERT_NAME}.key
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>
    BrowserMatch "MSIE [2-6]" \\
        nokeepalive ssl-unclean-shutdown \\
        downgrade-1.0 force-response-1.0
    BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
</VirtualHost>
EOF

# Configure FastCGI mod
sed -i '$d' /etc/apache2/mods-available/fastcgi.conf
cat <<EOF >> /etc/apache2/mods-available/fastcgi.conf
  AddType application/x-httpd-fastphp5 .php
  Action application/x-httpd-fastphp5 /php5-fcgi
  Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
  FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -socket /var/run/php5-fpm.sock -pass-header Authorization
</IfModule>
EOF


# Update Apache settings
echo "ServerName localhost" >> /etc/apache2/apache2.conf
sed -i '/Listen 443/i\ \ \ \ NameVirtualHost *:443' /etc/apache2/ports.conf
cd /etc/apache2/sites-available/ && a2ensite "${SERVER_NAME}".conf
a2dissite 000-default
a2enmod rewrite actions ssl

service apache2 restart

echo "Apache configured."

# =============================================================================

echo "--- Installing Composer ---"

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
echo "Composer installed."

# =============================================================================

echo "--- Installing vim ---"

apt-get install -y vim

cat <<EOF > /home/vagrant/.vimrc
"
" ~/.vimrc
"
" Compatability
set nocompatible         " use vim defaults instead of vi
set encoding=utf-8       " always encode in utf
filetype plugin indent on
syntax on
" General
set backspace=2           " enable <BS> for everything
"set colorcolumn=80       " visual indicator of column
set completeopt-=preview  " dont show preview window
"set cursorline            " visual indicator of current line
set hidden                " hide when switching buffers, don't unload
set laststatus=2          " always show status line
set lazyredraw            " don't update screen when executing macros
set mouse=a               " enable mouse in all modes
set showmode              " show mode in status line
set nowrap                " disable word wrap
set number                " show line numbers
set showcmd               " show command on last line of screen
set showmatch             " show bracket matches
set spelllang=en_au       " spell check with Australian English
set textwidth=0           " don't break lines after some maximum width
set ttyfast               " increase chars sent to screen for redrawing
"set ttyscroll=3           " limit lines to scroll to speed up display
set title                 " use filename in window title
set wildmenu              " enhanced cmd line completion
" Folding
set foldignore=           " don't ignore anything when folding
set foldlevelstart=99     " no folds closed on open
set foldmethod=indent     " collapse code using indent levels
set foldnestmax=20        " limit max folds for indent and syntax methods
" Tabs
set autoindent            " copy indent from previous line
set expandtab             " replace tabs with spaces
set shiftwidth=4          " spaces for autoindenting
set smarttab              " <BS> removes shiftwidth worth of spaces
set softtabstop=4         " spaces for editing, e.g. <Tab> or <BS>
set tabstop=4             " spaces for <Tab>
" Searches
set hlsearch              " highlight search results
set incsearch             " search whilst typing
set ignorecase            " case insensitive searching
set smartcase             " override ignorecase if upper case typed
" Colours
set t_Co=256
set background=dark
" Copy to OSX CLIPBOARD
"vnoremap ,c "*y
" Vimdiff display
if &diff
    set diffopt=filler,foldcolumn:0
endif
EOF
echo "Vim installed."

# =============================================================================

echo "--- Finalising installation ---"
updatedb && echo "mlocate DB updated."

# =============================================================================

echo "--- FINISHED ---"
echo "View the dev site via http://${SERVER_NAME}"
