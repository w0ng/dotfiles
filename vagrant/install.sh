#!/usr/bin/env bash
#
# Based on https://gist.github.com/fideloper/7074502

echo "--- Installing base items ---"
apt-get update
apt-get install -y build-essential curl wget python-software-properties mlocate

echo "--- Setting MySQL password to 'root' ---"
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

echo "--- Installing Apache, PHP and MySQL ---"
apt-get install -y git-core php5 apache2 libapache2-mod-php5 php5-mysql php5-curl php5-gd php5-mcrypt php5-ldap php5-xdebug mysql-server 

echo "--- Configuring Apache ---"
a2enmod rewrite
mv /etc/apache2/sites-available/default /etc/apache2/sites-available/default.bak
cat <<EOF > /etc/apache2/sites-available/default
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    RewriteEngine On
    DocumentRoot /vagrant/public
    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>
    <Directory /vagrant/public>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^([^\.]+)$ \$1.php [NC,L]
    </Directory>
        ErrorLog \${APACHE_LOG_DIR}/error.log
        LogLevel warn
        CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

echo "--- Configuring PHP ---"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini

echo "--- Configuring Xdebug ---"
cat << EOF | tee -a /etc/php5/conf.d/xdebug.ini
xdebug.scream=1
xdebug.cli_color=1
xdebug.show_local_vars=1
EOF

echo "--- Installing Composer ---"
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "--- Installing vim ---"
apt-get install -y vim
cat <<EOF > /home/vagrant/.vimrc
"
" ~/.vimrc
"
" Based on https://github.com/w0ng/dotfiles/blob/master/.vimrc
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

echo "--- Finalising installation ---"
service apache2 restart
updatedb

echo "--- DONE ---"
