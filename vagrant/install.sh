#!/usr/bin/env bash
#
# Based on https://github.com/fideloper/Vaprobash

# =============================================================================

echo "--- Installing base packages ---"

apt-get update
apt-get upgrade
apt-get install -y \
    build-essential \
    curl \
    git-core \
    mlocate \
    python-software-properties \
    unzip

# =============================================================================

echo "--- Creating a wildcard self-signed SSL Certificate ---"

# Based on https://serversforhackers.com/ssl-certs/
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

[[ ! -d "$SSL_DIR" ]] && sudo mkdir -p "$SSL_DIR"

# Generate private key, csr and certificate
sudo openssl genrsa \
    -out "$SSL_DIR/xip.io.key" 2048

sudo openssl req \
    -new \
    -subj "$(echo -n "$SUBJ" | tr "\n" "/")" \
    -key "$SSL_DIR/xip.io.key" \
    -out "$SSL_DIR/xip.io.csr" \
    -passin pass:$PASSPHRASE

sudo openssl x509 \
    -req \
    -days 365 \
    -in "$SSL_DIR/xip.io.csr" \
    -signkey "$SSL_DIR/xip.io.key" \
    -out "$SSL_DIR/xip.io.crt"

# =============================================================================

echo "--- Installing Apache, PHP and MySQL ---"

# MySQL: preset root password to enable non-interactive package installation
debconf-set-selections <<< \
    'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< \
    'mysql-server mysql-server/root_password_again password root'

apt-get install -y \
    apache2 \
    libapache2-mod-php5 \
    mysql-server \
    php5 \
    php5-curl \
    php5-gd \
    php5-gmp \
    php5-imagick \
    php5-intl \
    php5-ldap \
    php5-mcrypt \
    php5-memcached \
    php5-mysql \
    php5-xdebug

# =============================================================================

echo "--- Configuring PHP ---"

# PHP: Display all errors
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" \
    /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" \
    /etc/php5/apache2/php.ini

# Xdebug: enable extension, do not limit output
cat > $(find /etc/php5 -name xdebug.ini) << EOF
zend_extension=$(find /usr/lib/php5 -name xdebug.so)
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream= 0
xdebug.cli_color= 1
xdebug.show_local_vars= 1
xdebug.var_display_max_depth = -1
xdebug.var_display_max_children = -1
xdebug.var_display_max_data = -1
EOF

# =============================================================================

echo "--- Configuring Apache ---"

SERVER="${1}.xip.io"
DOC_ROOT="$2"
ALIAS="$3"
CERT_PATH="/etc/ssl/xip.io"
CERT_NAME="xip.io"

[[ ! -d "$DOC_ROOT" ]] && mkdir -p "$DOC_ROOT"

# Create a vhost using arguments supplied by VagrantFile
[[ ! -f "${DOC_ROOT}/${SERVER}.conf" ]] && \
    cat <<EOF > /etc/apache2/sites-available/${SERVER}.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName ${SERVER}
    ServerAlias ${ALIAS}
    DocumentRoot ${DOC_ROOT}
    <Directory ${DOC_ROOT}>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^([^\.]+)$ \$1.php [NC,L]
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${SERVER}-error.log
    LogLevel warn
    CustomLog \${APACHE_LOG_DIR}/${SERVER}-access.log combined
</VirtualHost>
EOF

# Create an SSL vhost using the xip.io cert created earlier
[[ -d "${CERT_PATH}" ]] && \
    cat <<EOF >> /etc/apache2/sites-available/${SERVER}.conf
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName ${SERVER}
    ServerAlias ${ALIAS}
    DocumentRoot ${DOC_ROOT}
    <Directory ${DOC_ROOT}>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^([^\.]+)$ \$1.php [NC,L]
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${SERVER}-error.log
    LogLevel warn
    CustomLog \${APACHE_LOG_DIR}/${SERVER}-access.log combined
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

# Update global Apache settings
echo "ServerName localhost" >> /etc/apache2/apache2.conf
cd /etc/apache2/sites-available/ && a2ensite ${SERVER}.conf
a2dissite 000-default
a2enmod rewrite actions ssl

# =============================================================================

echo "--- Installing Composer ---"

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# =============================================================================

echo "--- Installing vim ---"

apt-get install -y vim

# Based on https://github.com/w0ng/dotfiles/blob/master/.vimrc
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
"set colorcolumn=120       " visual indicator of column
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

# =============================================================================

echo "--- Finalising installation ---"
apache2ctl graceful && echo "Apache restarted gracefully."
updatedb && echo "mlocate DB updated."

# =============================================================================

echo "--- FINISHED ---"
echo "View the dev site via http://${SERVER} or http://${ALIAS}"
