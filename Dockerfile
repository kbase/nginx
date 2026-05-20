FROM openresty/openresty:1.29.2.4-alpine-fat@sha256:af355ebd6f01e580823b6718e8a2e39be3b45d9437fc92144e43ac72020f7461
ENV DEBIAN_FRONTEND=noninteractive

COPY deployment /kb/deployment

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        curl vim htop wget \
        pcre openssl zlib ca-certificates && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /etc/nginx/ssl /etc/nginx/conf.d /etc/nginx/sites-enabled /var/log/nginx && \
    touch /var/log/nginx/access.log /var/log/nginx/error.log

RUN rm -f /usr/local/openresty/nginx/conf/nginx.conf \
          /etc/nginx/conf.d/default.conf

RUN ln -s /usr/local/openresty/nginx/conf/mime.types /etc/nginx/mime.types


RUN mkdir -p /kb/deployment/bin && \
    wget -O /tmp/dockerize.tar.gz \
      https://github.com/kbase/dockerize/raw/master/dockerize-linux-amd64-v0.6.1.tar.gz && \
    tar xzf /tmp/dockerize.tar.gz -C /tmp && \
    mv /tmp/dockerize /kb/deployment/bin/ && \
    rm /tmp/dockerize.tar.gz

ENTRYPOINT [ "/kb/deployment/bin/dockerize" ]