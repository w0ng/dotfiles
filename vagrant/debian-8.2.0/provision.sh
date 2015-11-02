#!/usr/bin/env bash
#
# References:
#   https://github.com/fideloper/Vaprobash
#   https://serversforhackers.com/ssl-certs/
#   https://www.linode.com/docs/websites/apache/running-fastcgi-php-fpm-on-debian-7-with-apache
#   https://github.com/w0ng/dotfiles/blob/master/.vimrc

# =============================================================================

echo "--- Changing locale to Australia and timezone to Australia/Sydney ---"

export LANG="en_AU.UTF-8"
sed -ri 's/^([^#].*)/# \1/' /etc/locale.gen
echo "en_AU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

timedatectl set-timezone "Australia/Sydney"

# =============================================================================

echo "--- Adding non-free repository ---"

sed -ri "s/^(deb.* main)$/\1 non-free/" /etc/apt/sources.list

echo "non-free repository added."

# =============================================================================

echo "--- Installing base packages ---"

apt-get update
apt-get upgrade -y
apt-get install -y \
    curl \
    git-core \
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

# Set mysql root user password to 'vagrant'
debconf-set-selections <<< \
    'mysql-server mysql-server/root_password password vagrant'
debconf-set-selections <<< \
    'mysql-server mysql-server/root_password_again password vagrant'

echo "--- Installing Apache, MySQL and PHP ---"

apt-get install -y \
    apache2 \
    apache2-mpm-worker \
    libapache2-mod-fastcgi \
    mysql-server \
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
    php5-mysql \
    php5-xdebug

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
[[ ! -d "/vagrant/tmp" ]] && mkdir -p "/vagrant/tmp"
cat > "$(find /etc/php5 -name xdebug.ini)" <<EOF
zend_extension=$(find /usr/lib/php5 -name xdebug.so)
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
xdebug.profiler_output_dir = /vagrant/tmp
EOF

service php5-fpm restart

echo "PHP configured."

# =============================================================================

echo "--- Configuring MySQL ---"

# Set strict mode
sed -i '/\[mysqld\]/a sql_mode = "STRICT_ALL_TABLES,ONLY_FULL_GROUP_BY,NO_ENGINE_SUBSTITUTION"' \
    /etc/mysql/my.cnf

# Fix deprecated defaults for MySQL 5.5
sed -i 's/key_buffer[^_]/key_buffer_size/' \
        /etc/mysql/my.cnf
sed -i 's/myisam-recover[^-]/myisam-recover-options/' \
        /etc/mysql/my.cnf


service mysql restart

echo "MySQL configured."

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
        Require all granted
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
        Require all granted
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
  <Directory /usr/lib/cgi-bin>
    Require all granted
  </Directory>
</IfModule>
EOF


# Update Apache settings
echo "ServerName localhost" >> /etc/apache2/apache2.conf
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

echo "--- FINISHED ---"

echo "View the dev site via http://${SERVER_NAME}"
