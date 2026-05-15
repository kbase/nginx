FROM debian:bookworm-slim AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential git wget ca-certificates \
        libpcre3-dev libssl-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://nginx.org/download/nginx-1.31.0.tar.gz && \
    tar -xzf nginx-1.31.0.tar.gz && \
    git clone https://github.com/openresty/headers-more-nginx-module.git && \
    cd headers-more-nginx-module && \
    git checkout v0.39 && \
    cd ../nginx-1.31.0 && \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_gzip_static_module \
        --add-module=../headers-more-nginx-module && \
    make -j$(nproc) && \
    make install


FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

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