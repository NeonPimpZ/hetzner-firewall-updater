FROM alpine:latest

RUN apk add --no-cache curl jq bash

COPY update-hetzner-home-ip.sh /usr/local/bin/update-hetzner-home-ip.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/update-hetzner-home-ip.sh /entrypoint.sh

RUN echo "0 5 * * * /usr/local/bin/update-hetzner-home-ip.sh >> /proc/1/fd/1 2>&1" \
    > /etc/crontabs/root

CMD ["/entrypoint.sh"]