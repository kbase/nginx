ARG STAGE1TAG=develop
FROM kbase/narrative:${STAGE1TAG} as narrative

# Cribbed from https://hub.docker.com/r/owasp/modsecurity/dockerfile
FROM debian:jessie as modsecurity-build
MAINTAINER Chaim Sanders chaim.sanders@gmail.com

ARG RESTY_VERSION="1.13.6.1"

# Install Prereqs
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq && \
    apt install -qq -y --no-install-recommends --no-install-suggests \
    ca-certificates \
    automake \
    autoconf \
    build-essential \
    libcurl4-openssl-dev \
    libpcre++-dev \
    libtool \
    libxml2-dev \
    libyajl-dev \
    lua5.2-dev \
    git \
    pkgconf \
    ssdeep \
    libgeoip-dev \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cd /opt && \
    git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
    cd ModSecurity && \
    git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && \
    make && \
    make install

RUN strip /usr/local/modsecurity/bin/* /usr/local/modsecurity/lib/*.a /usr/local/modsecurity/lib/*.so* && \
    cd /opt && \
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    export NGINX_VERSION=`echo $RESTY_VERSION |  sed -E "s/\.[0-9]+\$//"` && \
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xvzf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure --without-http_gzip_module --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules && \
    cp objs/ngx_http_modsecurity_module.so /opt/ModSecurity/

FROM openresty/openresty:jessie

# These ARGs values are passed in via the docker build command
ARG BUILD_DATE
ARG VCS_REF
ARG BRANCH

# Install the modsecurity related files
COPY --from=modsecurity-build /usr/local/modsecurity/ /usr/local/modsecurity/
RUN ldconfig && \
    mkdir /etc/nginx/modsecurity.d/
COPY --from=modsecurity-build /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsecurity.d/modsecurity.conf
COPY --from=modsecurity-build /opt/ModSecurity/ngx_http_modsecurity_module.so /usr/local/openresty/nginx/modules
RUN  echo "include /etc/nginx/modsecurity.d/modsecurity.conf" > /etc/nginx/modsecurity.d/include.conf

COPY deployment/ /kb/deployment/

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        software-properties-common ca-certificates apt-transport-https curl net-tools


# Split here just to manage the layer sizes
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
     lua5.1 luarocks liblua5.1-0 liblua5.1-0-dev liblua5.1-json liblua5.1-lpeg2 \
     libssl-dev apt-transport-https

RUN luarocks install luasocket;\
    luarocks install luajson;\
    luarocks install penlight;\
    luarocks install lua-spore;\
    luarocks install luacrypto

# Copy lua code from narrative repo
COPY --from=narrative /kb/dev_container/narrative/docker /kb/deployment/services/narrative/docker/


# Install docker binaries based on
# https://docs.docker.com/install/linux/docker-ce/debian/#install-docker-ce
# Also add the user to the groups that map to "docker" on Linux and "daemon" on
# MacOS
RUN apt-get install -y apt-transport-https software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce=18.03.0~ce-0~debian && \
    usermod -aG docker www-data && \
    usermod -g root www-data && \
    mkdir -p /kb/deployment/services/narrative/docker && \
    cp /kb/deployment/services/narrative/docker/proxy_mgr.lua /kb/deployment/services/narrative/docker/proxy_mgr2.lua

ADD githashes /tmp/githashes

RUN rm -rf /etc/nginx && \
    ln -s /usr/local/openresty/nginx/conf /etc/nginx && \
    cd /etc/nginx && \
    mkdir ssl /var/log/nginx && \
    mkdir /usr/local/openresty/nginx/conf/conf.d && \
    openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem -days 365 -nodes \
       -subj '/C=US/ST=California/L=Berkeley/O=Lawrence Berkeley National Lab/OU=KBase/CN=localhost' && \
    cd /tmp && \
	wget -N https://github.com/kbase/dockerize/raw/master/dockerize-linux-amd64-v0.6.1.tar.gz && \
	tar xvzf dockerize-linux-amd64-v0.6.1.tar.gz && \
    rm dockerize-linux-amd64-v0.6.1.tar.gz && \
	mv dockerize /kb/deployment/bin

COPY nginx-sites.d/ /usr/local/openresty/nginx/conf/sites-enabled


# The BUILD_DATE value seem to bust the docker cache when the timestamp changes, move to
# the end
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/kbase/nginx.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0-rc1" \
      us.kbase.vcs-branch=$BRANCH \
      maintainer="Steve Chan sychan@lbl.gov"


ENTRYPOINT [ "/kb/deployment/bin/dockerize" ]

# Here are some default params passed to dockerize. They would typically
# be overidden by docker-compose at startup
CMD [ "-template", "/kb/deployment/conf/.templates/openresty.conf.templ:/etc/nginx/nginx.conf", \
      "-template", "/kb/deployment/conf/.templates/minikb-narrative.templ:/etc/nginx/sites-enabled/minikb-narrative", \
      "-template", "/kb/deployment/conf/.templates/lua.templ:/etc/nginx/conf.d/lua", \
      "-env", "/kb/deployment/conf/localhost.ini", \
      "-stdout", "/var/log/nginx/access.log", \
      "-stdout", "/var/log/nginx/error.log", \
       "nginx" ]
