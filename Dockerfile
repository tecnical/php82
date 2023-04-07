###############################################################################
# Imagem PHP-8.1 baseada na imagem base alpine instalando todo o PHP do zero
#
FROM alpine:3.17.2
# Essentials
RUN apk add --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    zip unzip curl git supervisor

# Installing bash
RUN apk add bash \
    && sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

# Installing PHP
RUN apk add --no-cache php81-fpm php81-ctype php81-curl php81-dom php81-fileinfo php81-ftp php81-iconv php81-json \
    php81-ldap php81-mbstring php81-mysqlnd php81-openssl php81-pdo php81-pdo_sqlite php81-pear \
    php81-phar php81-posix php81-session php81-sodium php81-simplexml php81-sqlite3 php81-tokenizer php81-soap \
    php81-xml php81-xmlreader php81-xmlwriter php81-zlib php81-zip php81-bz2 php81-intl php81-gd \
    php81-imap php81-mysqli php81-bcmath php81-pdo_mysql php81-opcache ca-certificates && \
    ln -s /usr/sbin/php-fpm81 /usr/sbin/php-fpm  && \
    # ln -s /usr/bin/php81 /usr/bin/php
    set -x && \
    (delgroup www-data || true) \
    && addgroup -g 82 -S www-data \
    && adduser -u 82 -D -S -G www-data www-data \
    && mkdir -p /var/www/html && chown www-data:www-data /var/www/html

# Configuring PHP
COPY php.ini-production /etc/php81/php.ini
COPY zz-custom.conf /etc/php81/php-fpm.d/

# Ignoring the vrification of certificate
RUN echo "TLS_REQCERT never" >> /etc/openldap/ldap.conf

# Installing composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

# Configure supervisor
RUN mkdir -p /etc/supervisor.d/
COPY supervisord.ini /etc/supervisor.d/supervisord.ini

# Configure PHP
RUN mkdir -p /run/php/
RUN touch /run/php/php81-fpm.pid

COPY entrypoint.sh /usr/local/bin/

WORKDIR /var/www/html

STOPSIGNAL SIGQUIT

EXPOSE 9000

CMD ["supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]
