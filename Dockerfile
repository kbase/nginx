FROM openresty/openresty:1.29.2.3-bookworm-fat
COPY deployment /kb/deployment
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates curl net-tools wget vim htop openssl

RUN rm -rf /etc/nginx && \
    ln -s /usr/local/openresty/nginx/conf /etc/nginx && \
    cd /etc/nginx && \
    mkdir /etc/nginx/ssl /var/log/nginx && \
    mkdir /usr/local/openresty/nginx/conf/conf.d && \
    openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem -days 365 -nodes \
       -subj '/C=US/ST=California/L=Berkeley/O=Lawrence Berkeley National Lab/OU=KBase/CN=localhost' && \
    cd /tmp && \
	wget -N https://github.com/kbase/dockerize/raw/master/dockerize-linux-amd64-v0.6.1.tar.gz && \
	tar xvzf dockerize-linux-amd64-v0.6.1.tar.gz && \
    rm dockerize-linux-amd64-v0.6.1.tar.gz && \
    mkdir -kb/deployment/bin && \
	mv dockerize /kb/deployment/bin/

ENTRYPOINT [ "/kb/deployment/bin/dockerize" ]