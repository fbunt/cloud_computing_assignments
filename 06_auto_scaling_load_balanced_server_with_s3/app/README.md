# Simple Static Site
Create a basic index.html file here along with a Dockerfile to package it.
Follow steps 2 and 3
[HERE](https://tecadmin.net/tutorial/docker-run-static-website) for creating
the Dockerfile. I recomend `nginx` for the base. The `apache` image base has
been renamed to `httpd`. See below for the `nginx` and `httpd` documentaion.
You can use the `:alpine` tag for an extra small image with either.

* [nginx docs](https://hub.docker.com/_/nginx)
* [http docs](https://hub.docker.com/_/httpd)
