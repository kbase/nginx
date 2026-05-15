FROM openresty/openresty:bookworm-amd64@sha256:729b91706ca8dd543f60d1d538ae64a690efb1d066c0144dbbb1745110609915 AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential git perl dos2unix \
        libpcre3-dev libssl-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/openresty/openresty.git /tmp/openresty-src && \
    cd /tmp/openresty-src && \
    git checkout 4c1c9426e4ffc8a80756d87eca07e75aacb6fa4b && \
    make && \
    tar -xzf openresty-*.tar.gz && \
    cd openresty-*/ && \
    ./configure --prefix=/usr/local/openresty \
        --with-pcre-jit \
        --with-http_ssl_module \
        --with-http_v2_module && \
    make -j$(nproc) && \
    make install


# The above can be removed once they release a new version

FROM openresty/openresty:bookworm-amd64@sha256:729b91706ca8dd543f60d1d538ae64a690efb1d066c0144dbbb1745110609915
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=builder /usr/local/openresty /usr/local/openresty

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
