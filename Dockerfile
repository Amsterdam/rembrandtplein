FROM nginx
MAINTAINER datapunt.ois@amsterdam.nl

EXPOSE 80

RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade \
	&& apt-get install -y nginx git curl rsync php7.0-fpm php7.0-mcrypt php7.0-intl php7.0-pgsql php7.0-curl git vim curl cron rsync php7.0-fpm php7.0-intl php7.0-pgsql php7.0-curl php7.0-cli php7.0-gd php7.0-intl php7.0-mbstring php7.0-mcrypt php7.0-opcache php7.0-sqlite3 php7.0-xml php7.0-xsl php7.0-zip php7.0-igbinary php7.0-json php7.0-memcached php7.0-msgpack php7.0-xmlrpc \
    && apt-get check && apt-get clean && apt-get -y autoremove \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
	&& usermod -a -G www-data nginx \
	&& ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime \
	&& curl https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -o /usr/bin/wait-for-it.sh \
	&& chmod +x /usr/bin/wait-for-it.sh

COPY . /app
COPY /Docker/parameters.yml /app/app/config/parameters.yml
COPY /Docker/parameters_env.php /app/app/config/parameters_env.php

RUN chown -R www-data:www-data /app/app/cache \
    && chmod 770 /app/app/cache \
    && chown -R www-data:www-data /app/app/logs \
    && chmod 770 /app/app/logs \
    && chmod 777 /app/docker-entrypoint.sh

COPY app/Resources/server-config-examples/docker.conf /etc/nginx/conf.d/rembrandtplein.conf
RUN rm /etc/nginx/conf.d/default.conf \
  && sed -i '/\;listen\.mode\ \=\ 0660/c\listen\.mode=0666' /etc/php/7.0/fpm/pool.d/www.conf \
  && sed -i '/pm.max_children = 5/c\pm.max_children = 20' /etc/php/7.0/fpm/pool.d/www.conf \
  && sed -i '/\;pm\.max_requests\ \=\ 500/c\pm\.max_requests\ \=\ 100' /etc/php/7.0/fpm/pool.d/www.conf \
  && echo "server_tokens off;" > /etc/nginx/conf.d/extra.conf \
  && echo "client_max_body_size 20m;" >> /etc/nginx/conf.d/extra.conf \
  && sed -i '/upload_max_filesize \= 2M/c\upload_max_filesize \= 20M' /etc/php/7.0/fpm/php.ini \
  && sed -i '/post_max_size \= 8M/c\post_max_size \= 21M' /etc/php/7.0/fpm/php.ini \
  && sed -i '/\;date\.timezone \=/c\date.timezone = Europe\/Amsterdam' /etc/php/7.0/fpm/php.ini \
  && sed -i '/\;security\.limit_extensions \= \.php \.php3 \.php4 \.php5 \.php7/c\security\.limit_extensions \= \.php' /etc/php/7.0/fpm/pool.d/www.conf \
  && sed -e 's/;clear_env = no/clear_env = no/' -i /etc/php/7.0/fpm/pool.d/www.conf

WORKDIR /app

RUN curl -sS https://getcomposer.org/installer | php \
	&& php composer.phar install --prefer-dist --no-scripts

CMD /app/docker-entrypoint.sh
