# Makefile for KBase specific nginx alpine
#
# Author: Steve Chan sychan@lbl.gov
#

NAME := "kbase/nginx"

all: docker_image

docker_image:
	wget -N https://github.com/kbase/dockerize/raw/master/dockerize-linux-amd64-v0.6.1.tar.gz
	tar xvzf dockerize-linux-amd64-v0.6.1.tar.gz
	cp dockerize deployment/bin
	date > build-nginx.trigger
	IMAGE_NAME=$(NAME) hooks/build
	rm dockerize dockerize-linux-amd64-v0.6.1.tar.gz deployment/bin/dockerize

push_image:
	IMAGE_NAME=$(NAME) ./push2dockerhub.sh
