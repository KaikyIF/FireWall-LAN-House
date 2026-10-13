
FROM nginx:alpine

RUN apk add --no-cache iproute2 postgresql-client

COPY entrypoint.sh /entrypoint.sh

RUN sed -i 's/\r$//' /entrypoint.sh \
    && chmod +x /entrypoint.sh

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
