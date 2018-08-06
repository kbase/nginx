# Makefile for KBase specific nginx alpine
#
# Author: Steve Chan sychan@lbl.gov
#

BRANCH := ${TRAVIS_BRANCH:-`git symbolic-ref --short HEAD`}
NAME := "kbase/nginx:$(BRANCH)"

all: docker_image

docker_image:
	IMAGE_NAME=$(NAME) hooks/build

push_image:
	IMAGE_NAME=$(NAME) ./push2dockerhub.sh
