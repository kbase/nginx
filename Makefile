# Makefile for KBase specific nginx alpine
#
# Author: Steve Chan sychan@lbl.gov
#

NAME := "kbase/nginx"

all: docker_image

docker_image:
	IMAGE_NAME=$(NAME) hooks/build

push_image:
	IMAGE_NAME=$(NAME) ./push2dockerhub.sh
