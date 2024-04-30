###############################################################################
# Imagem PHP-8.2 baseada na imagem base alpine instalando o PHP do zero
#
FROM alpine:3.19.1

ARG UID=1000
ARG GID=1000
ARG USER=suporte

# Essentials
RUN apk add --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    zip unzip curl git supervisor openssl ca-certificates \
    && apk cache clean \

# Installing bash
RUN apk add bash \
    && apk cache clean \
    && sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

# Installing PHP
RUN apk add --no-cache php82-fpm php82-ctype php82-curl php82-dom \
    php82-fileinfo php82-ftp php82-iconv php82-json php82-ldap php82-mbstring \
    php82-mysqlnd php82-openssl php82-pdo php82-pdo_sqlite php82-pear \
    php82-phar php82-posix php82-session php82-sodium php82-simplexml \
    php82-sqlite3 php82-tokenizer php82-soap php82-xml php82-xmlreader \
    php82-xmlwriter php82-zlib php82-zip php82-bz2 php82-intl php82-gd \
    php82-imap php82-mysqli php82-bcmath php82-pdo_mysql php82-opcache \
    php82-pdo_sqlite ca-certificates \
    && apk cache clean \
    && ln -s /usr/sbin/php-fpm82 /usr/sbin/php-fpm \
    && set -x && \
    (delgroup "${USER}" || true) \
    && addgroup -g "${GID}" -S "${USER}" \
    && adduser -u "${UID}" -D -S -G "${USER}" "${USER}" \
    && mkdir -p /var/www/html && chown "${USER}":"${USER}" /var/www/html

COPY php.ini-production /etc/php82/php.ini
COPY zz-custom.conf /etc/php82/php-fpm.d/

# Installing composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

# Configure supervisor
RUN mkdir -p /etc/supervisor.d/
COPY supervisord.ini /etc/supervisor.d/supervisord.ini

# Configurar o Openssl
RUN mkdir -p /usr/local/ssl/certs
RUN /usr/bin/c_rehash

RUN mkdir /etc/ldap \
    && echo "TLS_REQCERT never" >> /etc/openldap/ldap.conf \
    && echo "TLS_REQCERT never" >> /etc/ldap/ldap.conf

# Configure PHP
RUN mkdir -p /run/php/
RUN touch /run/php/php82-fpm.pid

COPY entrypoint.sh /usr/local/bin/

# Switch to user
USER "${UID}":"${GID}"

WORKDIR /var/www/html

STOPSIGNAL SIGQUIT

EXPOSE 9000

CMD ["supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]
#CMD ["bash"]
