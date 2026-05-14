FROM openresty/openresty:1.29.2.3-bookworm-fat

ENV DEBIAN_FRONTEND=noninteractive

COPY deployment /kb/deployment

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends curl vim htop wget && \
    rm -rf /var/lib/apt/lists/*

RUN rm -rf /etc/nginx && \
    ln -s /usr/local/openresty/nginx/conf /etc/nginx && \
    mkdir -p /etc/nginx/ssl /etc/nginx/conf.d /etc/nginx/sites-enabled /var/log/nginx

RUN mkdir -p /kb/deployment/bin && \
    wget -O /tmp/dockerize.tar.gz \
      https://github.com/kbase/dockerize/raw/master/dockerize-linux-amd64-v0.6.1.tar.gz && \
    tar xzf /tmp/dockerize.tar.gz -C /tmp && \
    mv /tmp/dockerize /kb/deployment/bin/ && \
    rm /tmp/dockerize.tar.gz

ENTRYPOINT [ "/kb/deployment/bin/dockerize" ]