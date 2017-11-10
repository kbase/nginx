# Makefile for KBase specific nginx alpine
#
# Author: Steve Chan sychan@lbl.gov
#

NAME := "kbase/nginx"

all: docker_image

docker_image:
	wget -N https://github.com/kbase/dockerize/raw/dist/dockerize-alpine-linux-amd64-v0.5.0.tar.gz
	tar xvzf dockerize-alpine-linux-amd64-v0.5.0.tar.gz
	cp dockerize deployment/bin
	IMAGE_NAME=$(NAME) hooks/build

push_image:
	IMAGE_NAME=$(NAME) ./push2dockerhub.sh
