# nginx
Version of standard nginx image that supports KBase configuration

# Passing environment variables through Nginx to the narrative containers

When this image is built, it copies the lua code that is in the narrative repo. That lua
code can be found at https://github.com/kbase/narrative/tree/develop/docker

Within the Docker.lua file, an environment variable NARR_ENV_VARS is looked for, and if
found, it is used to populate the default environment variables used when starting
narratives. This can be used to set environment variables that the narrative container
needs to be customized for the environment it runs in.

Here are examples of starting the nginx image so that the narratives are started with
the CONFIG_ENV variable set for ci, appdev and prod respectively. This variable is
expanded in the config.json template to set the appropriate API endpoints to use

~~~~
docker run -it -v /var/run/docker.sock:/var/run/docker.sock -e 'NARR_ENV_VARS=["CONFIG_ENV=ci"]' kbase/nginx

docker run -it -v /var/run/docker.sock:/var/run/docker.sock -e 'NARR_ENV_VARS=["CONFIG_ENV=appdev"]' kbase/nginx

docker run -it -v /var/run/docker.sock:/var/run/docker.sock -e 'NARR_ENV_VARS=["CONFIG_ENV=prod"]' kbase/nginx
~~~~

Additional environment variables can be added to the JSON array assigned to NARR_ENV_VARS, the following command would also set the VERSION_CHECK environment variable (also used by narrative for configuration)
~~~
run -it -v /var/run/docker.sock:/var/run/docker.sock -e 'NARR_ENV_VARS=["CONFIG_ENV=appdev","VERSION_CHECK=https://narrative.kbase.us/narrative_version"]' kbase/nginx
~~~
