#!/bin/bash

# Prevent apt asking for input
sudo export DEBIAN_FRONTEND=noninteractive

# Install git
sudo apt-get install git-core

# Install Apache
sudo apt-get install apache2 libapache2-mod-fastcgi
sudo apt-get install python-software-properties

# Install PHP
sudo add-apt-repository ppa:ondrej/php
sudo apt-get -y update
sudo apt-get install php7.2 php7.2-fpm

sudo a2enmod actions fastcgi alias proxy_fcgi

echo ">>> setting up default vhost config"
sudo echo '<VirtualHost *:80>
    #ServerName example.com
    #ServerAlias www.example.com
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
	# apache 2.4.10+ can use proxy to unix socket
	SetHandler "proxy:unix:/var/run/php/php7.3-fpm.sock|fcgi://localhost/"

	# or we can also use a tcp socket
        #SetHandler "proxy:fcgi://127.0.0.1:9000"
    </FilesMatch>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

sudo systemctl restart apache2

echo ">>> create an info.php"
sudo echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# Install mariadb
echo ">>> installing mariadb"
sudo apt-get install -y software-properties-common

# you need to change the password
MARIADB_VERSION='10.3'
MARIADB_PASSWORD='topsecret_pw123'

sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository "deb [arch=amd64,arm64,i386,ppc64el] http://ftp.ddg.lth.se/mariadb/repo/$MARIADB_VERSION/ubuntu xenial main"
sudo apt-get update
sudo apt-get install mariadb-server mariadb-client

# Install without password prompt
sudo debconf-set-selections <<< "maria-dbserver-$MARIADB_VERSION mysql-server/root_password password '$MARIADB_PASSWORD'"
sudo debconf-set-selections <<< "maria-dbserver-$MARIADB_VERSION mysql-server/root_password_again password '$MARIADB_PASSWORD'"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y -q mariadb-server

sudo systemctl restart mysql

# install java to run jenkins
sudo apt-get install -y default-jre

# install jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins
