FROM 1.29.2.4-0-alpine-fat
ENV DEBIAN_FRONTEND=noninteractive

COPY deployment /kb/deployment

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl vim htop wget \
        libpcre3 libssl3 zlib1g ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl /etc/nginx/conf.d /etc/nginx/sites-enabled /var/log/nginx

RUN mkdir -p /kb/deployment/bin && \
    wget -O /tmp/dockerize.tar.gz \
      https://github.com/kbase/dockerize/raw/master/dockerize-linux-amd64-v0.6.1.tar.gz && \
    tar xzf /tmp/dockerize.tar.gz -C /tmp && \
    mv /tmp/dockerize /kb/deployment/bin/ && \
    rm /tmp/dockerize.tar.gz

ENTRYPOINT [ "/kb/deployment/bin/dockerize" ]