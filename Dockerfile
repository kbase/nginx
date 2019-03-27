FROM openresty/openresty:jessie

# These ARGs values are passed in via the docker build command
ARG BUILD_DATE
ARG VCS_REF
ARG BRANCH

COPY deployment/ /kb/deployment/

RUN cp /kb/deployment/conf/sources.list /etc/apt/sources.list && \
    apt-get update && \
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

# Copy lua code to destination
# COPY --from=narrative /kb/dev_container/narrative/docker /kb/deployment/services/narrative/docker/
RUN mkdir -p /kb/deployment/services/narrative && \
    mv /kb/deployment/docker /kb/deployment/services/narrative

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
