FROM alpine:latest

RUN apk add --no-cache \
    curl \
    nmap \
    iproute2 \
    iputils

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]