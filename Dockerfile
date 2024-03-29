FROM openresty/openresty:buster

# These ARGs values are passed in via the docker build command
ARG BUILD_DATE
ARG VCS_REF
ARG BRANCH

COPY deployment/ /kb/deployment/

#RUN cp /kb/deployment/conf/sources.list /etc/apt/sources.list && \
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        software-properties-common ca-certificates apt-transport-https curl net-tools wget

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
      "-env", "/kb/deployment/conf/localhost.ini", \
      "-stdout", "/var/log/nginx/access.log", \
      "-stdout", "/var/log/nginx/error.log", \
       "nginx" ]
