FROM nginx:alpine

COPY deployment /kb/deployment

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        curl vim htop wget \
        ca-certificates && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /etc/nginx/ssl /etc/nginx/conf.d /etc/nginx/sites-enabled /var/log/nginx && \
    touch /var/log/nginx/access.log /var/log/nginx/error.log

RUN rm -f /etc/nginx/conf.d/default.conf

RUN mkdir -p /kb/deployment/bin && \
    wget -O /tmp/dockerize.tar.gz \
      https://github.com/kbase/dockerize/raw/master/dockerize-linux-amd64-v0.6.1.tar.gz && \
    tar xzf /tmp/dockerize.tar.gz -C /tmp && \
    mv /tmp/dockerize /kb/deployment/bin/ && \
    rm /tmp/dockerize.tar.gz

ENTRYPOINT [ "/kb/deployment/bin/dockerize" ]