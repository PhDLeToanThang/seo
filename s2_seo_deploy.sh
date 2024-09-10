#!/bin/bash
####################################################
#Code UNIX:
# SEO 5.x = Matomo version: 5.1.1
# PHP version: 8.3.10
# NGINX 1.24, phpmyadmin 5.2.1
# MySQL version: 10.11.8-MariaDB-0ubuntu0.24.04.1
# OS ubuntu 24.04.1 LTS 
# D:\Documents\GitHub\seo\seo-deploy.sh
# Code Deploy SEO server On-premise:
# Install SEO on Ubuntu 22.04 linux server OS:
# Matomo is a powerful open source Non-IT Marketing and Behavior management of Customers/visitors (SEO) software tool 
# designed to help you plan trending , tracing or tracking Web buy/shell/e-commerce shop, digital content tracking such as E-book, Reader-paper, device book reader...
# This is source code deploy for Multi-tenance for more instance SEO.
####################################

#Step 1: Update Ubuntu
sudo apt update -y

#You can also upgrade installed packages by running the following command.
sudo apt upgrade -y

clear
cd ~
############### Tham số cần thay đổi ở đây ###################
echo "FQDN: e.g: seo.company.vn"   # Đổi địa chỉ web thứ nhất Website Master for Resource code - để tạo cùng 1 Source code duy nhất 
read -e FQDN
echo "dbname: e.g: seodata"   # Tên DBNane
read -e dbname
echo "dbuser: e.g: userseodata"   # Tên User access DB lmsatcuser
read -e dbuser
echo "Database Password: e.g: P@$$w0rd-1.22"
read -s dbpass
echo "phpmyadmin folder name: e.g: seodbadmin"   # Đổi tên thư mục phpmyadmin khi add link symbol vào Website 
read -e phpmyadmin
echo "SEO Folder Data: e.g: seodata"   # Tên Thư mục chưa Data vs Cache
read -e FOLDERDATA
echo "dbtype name: e.g: mariadb"   # Tên kiểu Database
read -e dbtype
echo "dbhost name: e.g: localhost"   # Tên Db host connector
read -e dbhost
echo "Your Email address fro Certbot e.g: thang@company.vn" # Địa chỉ email của bạn để quản lý CA
read -e emailcertbot

GitSEOversion="matomo-latest"

echo "run install? (y/n)"
read -e run
if [ "$run" == n ] ; then
  exit
else

#Step 1. Install NGINX
sudo apt-get update -y
sudo apt-get install nginx -y
sudo systemctl stop nginx.service
sudo systemctl start nginx.service 
sudo systemctl enable nginx.service

#Step 2. Install MariaDB/MySQL
#Run the following commands to install MariaDB database for Moode. You may also use MySQL instead.
sudo apt-get install mariadb-server mariadb-client -y

#Like NGINX, we will run the following commands to enable MariaDB to autostart during reboot, and also start now.
sudo systemctl stop mysql.service
sudo systemctl start mysql.service
sudo systemctl enable mysql.service

#Run the following command to secure MariaDB installation.
#password mysql mariadb , i'm fixed: M@tKh@uS3cr3t  --> you must changit. 

sudo mysql_secure_installation  <<EOF
n
M@tKh@uS3cr3t
M@tKh@uS3cr3t
y
n
y
y
EOF
#You will see the following prompts asking to allow/disallow different type of logins. Enter Y as shown.
# Enter current password for root (enter for none): Just press the Enter
# Set root password? [Y/n]: Y
# New password: Enter password
# Re-enter new password: Repeat password
# Remove anonymous users? [Y/n]: Y
# Disallow root login remotely? [Y/n]: N
# Remove test database and access to it? [Y/n]:  Y
# Reload privilege tables now? [Y/n]:  Y
# After you enter response for these questions, your MariaDB installation will be secured.

#Step 3. Install PHP-FPM & Related modules
sudo apt-get install software-properties-common -y
sudo -S add-apt-repository ppa:ondrej/php -y
sudo apt update -y
sudo apt install php8.3-fpm php8.3-common php8.3-mbstring php8.3-xmlrpc php8.3-soap php8.3-gd php8.3-xml php8.3-intl php8.3-mysql php8.3-cli php8.3-mcrypt php8.3-ldap php8.3-zip php8.3-curl -y

#Open PHP-FPM config file.

#sudo nano /etc/php/8.3/fpm/php.ini
#Add/Update the values as shown. You may change it as per your requirement.
cat > /etc/php/8.3/fpm/php.ini <<END
file_uploads = On
allow_url_fopen = On
memory_limit = 1200M
upload_max_filesize = 4096M
max_execution_time = 360
cgi.fix_pathinfo = 0
date.timezone = asia/ho_chi_minh
max_input_time = 60
max_input_nesting_level = 64
max_input_vars = 5000
post_max_size = 4096M
END
systemctl restart php8.3-fpm.service

#Step 4. Create Moodle Database
#Log into MySQL and create database for Moodle.

# install tool mysql-workbench-community from Tonin Bolzan (tonybolzan)
sudo snap install mysql-workbench-community

mysql -uroot -prootpassword -e "DROP DATABASE IF EXISTS ${dbname};"
mysql -uroot -prootpassword -e "CREATE DATABASE IF NOT EXISTS ${dbname} CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -uroot -prootpassword -e "CREATE USER IF NOT EXISTS '${dbuser}'@'${dbhost}' IDENTIFIED BY \"${dbpass}\";"
mysql -uroot -prootpassword -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'${dbhost}';"
mysql -uroot -prootpassword -e "FLUSH PRIVILEGES;"
mysql -uroot -prootpassword -e "SHOW DATABASES;"

#Step 5. Next, edit the MariaDB default configuration file and define the innodb_file_format:
#nano /etc/mysql/mariadb.conf.d/50-server.cnf
#Add the following lines inside the [mysqld] section: 
cat > /etc/mysql/mariadb.conf.d/50-server.cnf <<END
[mysqld]
innodb_file_format = Barracuda
innodb_file_per_table = 1
innodb_large_prefix = ON
max_allowed_packet=128M
END
# sudo mysqld --max_allowed_packet=128M
# https://dev.mysql.com/doc/refman/8.4/en/packet-too-large.html

#Save the file then restart the MariaDB service to apply the changes.
systemctl restart mariadb

#Step 6. Download & Install SEO
#We will be using Git to install/update the SEO Core Application 
sudo apt install git -y

cd /opt
sudo apt-get install wget -y
#Run the following command to download SEO package.
#Download the SEO Code and Unzip 
wget https://builds.matomo.org/$GitSEOversion.zip && unzip $GitSEOversion.zip

cd matomo

#Retrieve a list of each branch available 
#sudo git branch -a
#Tell git which branch to track or use
#sudo git branch --track $GitSEOversion origin/$GitSEOversion

# Checkout matomo.js in case it was changed
#git checkout -- matomo.js

# Pull the latest code from Matomo repositories
#php console git:pull

# Upgrade the libraries in case there is any to be upgraded
#php composer.phar self-update > /dev/null
#php composer.phar install --no-dev > /dev/null

# Run the upgrade in case there was one
#php console core:update --yes > /dev/null

# Re-generate the matomo.js 
#php console custom-matomo-js:update > /dev/null

#git checkout 3.0.0
#git submodule update --init --recursive
#php composer.phar install --no-dev


#if get error
git fetch
#Finally, Check out the SEO version specified 
sudo git checkout $GitSEOversion
#Run the following command to extract package to NGINX website root folder.
sudo cp -R /opt/matomo /var/www/html/$FQDN
sudo mkdir /var/www/html/$FOLDERDATA
#Change the folder permissions.
sudo chown -R www-data:www-data /var/www/html/$FQDN/ 
sudo chmod -R 755 /var/www/html/$FQDN/ 
sudo chown www-data /var/www/html/$FOLDERDATA
chmod a+w /var/www/html/$FQDN/config

#https://matomo.org/faq/how-to/find-and-edit-matomo-config-file/
# make /var/www/html/$FQDN/config/config.ini.php
# We recommend using Matomo over secure SSL connections only. 
# To prevent insecure access over http, 
# add force_ssl = 1 to the General section in your Matomo config/config.ini.php file.
# Your database version indicates you might be using a MariaDb server. 
# If this is the case, please ensure to set [database] schema = Mariadb in the "config/config.ini.php" file, to ensure all database feature work as expected.
# Max Packet Size	It is recommended to configure a 'max_allowed_packet' size in your MySQL database of at least 64MB. 
# Configured is currently 16MB.

#Step 7: Finish SEO installation
cat > /etc/hosts <<END
127.0.0.1 $FQDN
127.0.0.1 localhost
# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
END

#Step 8. Configure NGINX

#Next, you will need to create an Nginx virtual host configuration file to host SEO:
# Mã xoá cấu hình cũ nếu có:

#$ nano /etc/nginx/conf.d/$FQDN.conf
echo 'server {' >> /etc/nginx/conf.d/$FQDN.conf
echo '	listen [::]:80; # remove this if you don't want Matomo to be reachable from IPv6'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  listen 80;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  server_name '${FQDN}';'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location / {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  return 301 https://$host$request_uri;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '}'  >> /etc/nginx/conf.d/$FQDN.conf
echo 'server {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  listen [::]:443 ssl http2;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  listen 443 ssl http2;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  server_name '${FQDN}';'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  access_log /var/log/nginx/${FQDN}.access.log;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  error_log /var/log/nginx/${FQDN}.error.log;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '	ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  include /etc/letsencrypt/options-ssl-nginx.conf;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  add_header Strict-Transport-Security "max-age=31536000" always;'  >> /etc/nginx/conf.d/$FQDN.conf
echo ' 	add_header Referrer-Policy origin always;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  add_header X-Content-Type-Options "nosniff" always;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  add_header X-XSS-Protection "1; mode=block" always;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  root /var/www/html/${FQDN};'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  index index.php;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  ocation ~ ^/(index|matomo|piwik|js/index|plugins/HeatmapSessionRecording/configs)\.php$ {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  include snippets/fastcgi-php.conf;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  fastcgi_param HTTP_PROXY "";'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location ~* ^.+\.php$ {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  deny all;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  return 403;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location / {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  try_files $uri $uri/ =404;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location ~ ^/(config|tmp|core|lang) {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  deny all;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  return 403;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location ~ /\.ht {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  deny  all;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  return 403;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location ~ js/container_.*_preview\.js$ {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  expires off;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  add_header Cache-Control 'private, no-cache, no-store';'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location ~ \.(gif|ico|jpg|png|svg|js|css|htm|html|mp3|mp4|wav|ogg|avi|ttf|eot|woff|woff2)$ {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  allow all;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  expires 1h;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  add_header Pragma public;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  add_header Cache-Control "public";'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location ~ ^/(libs|vendor|plugins|misc|node_modules) {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  deny all;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  return 403;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location ~/(.*\.md|LEGALNOTICE|LICENSE) {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  default_type text/plain;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '}'  >> /etc/nginx/conf.d/$FQDN.conf

#Save and close the file then verify the Nginx for any syntax error with the following command: 
nginx -t

#Step 9. Setup and Configure PhpMyAdmin
sudo apt update -y
sudo apt install phpmyadmin -y

#Step 10. gỡ bỏ apache:
sudo service apache2 stop
sudo apt-get purge apache2 apache2-utils apache2.2-bin apache2-common
sudo apt-get purge apache2 apache2-utils apache2-bin apache2.2-common

sudo apt-get autoremove
whereis apache2
apache2: /etc/apache2
sudo rm -rf /etc/apache2

sudo ln -s /usr/share/phpmyadmin /var/www/html/$FQDN/$phpmyadmin
sudo chown -R root:root /var/lib/phpmyadmin
sudo nginx -t

#Step 11. Nâng cấp PhpmyAdmin lên version 5.2.1:
sudo mv /usr/share/phpmyadmin/ /usr/share/phpmyadmin.bak
sudo mkdir /usr/share/phpmyadmin/
cd /usr/share/phpmyadmin/
sudo wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz
sudo tar xzf phpMyAdmin-5.2.1-all-languages.tar.gz
#Once extracted, list folder.
ls
#You should see a new folder phpMyAdmin-5.2.0-all-languages
#We want to move the contents of this folder to /usr/share/phpmyadmin
sudo mv phpMyAdmin-5.2.1-all-languages/* /usr/share/phpmyadmin
ls /usr/share/phpmyadmin
mkdir /usr/share/phpMyAdmin/tmp   # tạo thư mục cache cho phpmyadmin 

sudo systemctl restart nginx
systemctl restart php8.3-fpm.service

#Step 12. Install Certbot
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -n -d $FQDN --email $emailcertbot --agree-tos --redirect --hsts

# You should test your configuration at:
# https://www.ssllabs.com/ssltest/analyze.html?d=$FQDN
#/etc/letsencrypt/live/$FQDN/fullchain.pem
#   Your key file has been saved at:
#   /etc/letsencrypt/live/$FQDN/privkey.pem
#   Your cert will expire on yyyy-mm-dd. To obtain a new or tweaked
#   version of this certificate in the future, simply run certbot again
#   with the "certonly" option. To non-interactively renew *all* of
#   your certificates, run "certbot renew"


#Visit your server IP or hostname URL on /SEO. If it is your local machine, you can use: http://127.0.0.1/
#The 5-minute Matomo Installation
#Open your web browser and navigate to the URL to which you uploaded Matomo. 
#If everything is uploaded correctly, you should see the Matomo Installation Welcome Screen
#On the first page, Select your language.
#Accept License terms and click “Continue“.
#Choose ‘Install‘ for a completely new installation of SEO.
#Confirm that the Checks for the compatibility of your environment with the execution of SEO is successful.
#Configure Database connection
#Select SEO database to initialize.
#Finish the other setup steps to start using SEO.
#You should get the login page.
#Default logins / passwords are:
#    SEO/SEO for the administrator account
#    tech/tech for the technician account
#    normal/normal for the normal account
#    post-only/postonly for the postonly account
# On first login, you’re asked to change the password. Please set new password before configuring SEO. This is done under Administration > Users.
# This marks the end of installing SEO on Ubuntu 20.04/18.04. The next sections are about adding assets and other IT Management stuff for your 
# infrastructure/environment. For this, please refer to the SEO
fi
