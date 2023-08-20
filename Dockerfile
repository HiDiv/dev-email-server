FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ='Europe/Kaliningrad'

RUN apt-get clean \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
      postfix \
      dovecot-imapd dovecot-lmtpd dovecot-pop3d \
      nginx php-fpm php-curl php-xml \
      supervisor wget curl unzip patch dos2unix \
    && rm -rf /var/www/html \
    && rm -rf /etc/nginx/sites-enabled/* /etc/nginx/sites-available/* \
    && rm -rf /var/lib/apt/lists/*

COPY ./src /

RUN chmod +x /usr/local/bin/dovecot-checkpassword /usr/local/bin/postfix-wrapper.sh \
    && addgroup --system --gid 500 vmail \
    && adduser --system --home /var/mail/ --shell /usr/sbin/nologin --no-create-home --uid 500 --gid 500 vmail \
    && chown -R vmail:vmail /var/mail \
    && ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf \
    && ln -s /etc/nginx/sites-available/ssl.conf /etc/nginx/sites-enabled/ssl.conf \
    && wget --no-check-certificate \
      https://github.com/RainLoop/rainloop-webmail/releases/download/v1.17.0/rainloop-legacy-1.17.0.zip \
      -O /var/www/rainloop.zip \
    && unzip /var/www/rainloop.zip -d /var/www/rainloop \
    && rm /var/www/rainloop.zip \
    && cd /var/www/rainloop \
    && find . -type f -exec dos2unix {} \; \
    && patch -l -p1 < /var/www/rainloop.patch \
    && rm /var/www/rainloop.patch \
    && ln -s /var/www/rainloop /var/www/html/webmail \
    && find . -type d -exec chmod 755 {} \; \
    && find . -type f -exec chmod 644 {} \; \
    && chown -R www-data:www-data .

WORKDIR /
EXPOSE 25/tcp 465/tcp 143/tcp 993/tcp 110/tcp 995/tcp 80/tcp 443/tcp
VOLUME /var/mail/
VOLUME /var/www/rainloop/data/
CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
