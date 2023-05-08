FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ='Europe/Kaliningrad'

RUN apt-get clean \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
      postfix \
      dovecot-imapd dovecot-lmtpd dovecot-pop3d \
      nginx php-fpm php-curl php-xml \
      supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN rm -rf /etc/dovecot/private/* \
    && openssl genrsa -out /etc/dovecot/private/mail.localhost.key.pem 4096 \
    && openssl req -new -key /etc/dovecot/private/mail.localhost.key.pem -x509 -subj "/CN=mail.localhost" \
      -days 365 -out /etc/dovecot/private/mail.localhost.crt.pem -nodes

COPY ./src /
RUN chmod +x /usr/local/bin/dovecot-checkpassword /usr/local/bin/postfix-wrapper.sh \
    && addgroup --system --gid 500 vmail \
    && adduser --system --home /var/mail/ --shell /usr/sbin/nologin --no-create-home --uid 500 --gid 500 vmail \
    && chown -R vmail:vmail /var/mail

WORKDIR /
EXPOSE 25/tcp 465/tcp 143/tcp 993/tcp 110/tcp 995/tcp 80/tcp 443/tcp
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
