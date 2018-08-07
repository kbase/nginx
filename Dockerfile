ARG BRANCH=develop
FROM kbase/narrative:${BRANCH} as narrative

FROM openresty/openresty:jessie

# These ARGs values are passed in via the docker build command
ARG BUILD_DATE
ARG VCS_REF
ARG BRANCH

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
    mkdir -p /kb/deployment/services/narrative/docker

ADD githashes /tmp/githashes

RUN  ( echo "Git clone";date) > /tmp/git.log && \
    mkdir /kb/src && cd /kb/src && \
    git clone https://github.com/kbase/narrative -b $BRANCH && \
    grep -lr kbase.us/services /kb/| grep -v docs/ | \
    xargs sed -ri 's|https?://kbase.us/services|https://public.hostname.org:8443/services|g' && \
    date > /tmp/build-nginx.trigger && \
    /tmp/githashes /kb/src/ > /tmp/tags && \
    rm -rf /kb/src/narrative/.git && \
    mkdir -p /kb/deployment/services/narrative/docker && \
    cp -a /kb/src/narrative/docker/* /kb/deployment/services/narrative/docker/ && \
    rm -rf /kb/src && \
    cp /kb/deployment/services/narrative/docker/proxy_mgr.lua /kb/deployment/services/narrative/docker/proxy_mgr2.lua && \
    rm -rf /etc/nginx && \
    ln -s /usr/local/openresty/nginx/conf /etc/nginx && \
    cd /etc/nginx && \
    mkdir ssl /var/log/nginx && \
    openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem -days 365 -nodes \
       -subj '/C=US/ST=California/L=Berkeley/O=Lawrence Berkeley National Lab/OU=KBase/CN=localhost' && \
    cd /tmp && \
	wget -N https://github.com/kbase/dockerize/raw/master/dockerize-linux-amd64-v0.6.1.tar.gz && \
	tar xvzf dockerize-linux-amd64-v0.6.1.tar.gz && \
    rm dockerize-linux-amd64-v0.6.1.tar.gz && \
	mv dockerize /kb/deployment/bin

COPY --from=narrative /kb/dev_container/narrative/docker /kb/deployment/services/narrative/docker/


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
      "-env", "/kb/deployment/conf/localhost.ini", \
      "-stdout", "/var/log/nginx/access.log", \
      "-stdout", "/var/log/nginx/error.log", \
       "nginx" ]
