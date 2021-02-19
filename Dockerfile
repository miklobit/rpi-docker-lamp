FROM resin/rpi-raspbian:buster
MAINTAINER MikloBit <miklobit@gmail.com>

# Install packages
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
  apt-get install wget apt-transport-https ca-certificates

RUN  wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -  && \
  echo "deb https://packages.sury.org/php/ buster main" | sudo tee /etc/apt/sources.list.d/php7.list

RUN apt-get update && \
  apt-get purge 'php5*'

RUN apt-get -y install supervisor git 
RUN php7.0 php7.0-mysql 
RUN apache2 libapache2-mod-php7.0 
RUN mariadb-server pwgen nano
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Add image configuration and scripts
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL utils
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
RUN chmod 755 /*.sh

# config to enable .htaccess
ADD apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite && \
  service apache2 restart

# Configure /app folder with sample app
RUN mkdir app && echo "<?php phpinfo();?>" >> app/index.php
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html

#Enviornment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

# Add volumes for MySQL 
VOLUME  ["/etc/mysql", "/var/lib/mysql" ]

EXPOSE 80 443 3306
CMD ["/run.sh"]
