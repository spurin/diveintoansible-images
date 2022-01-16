FROM docker:dind

ENV DOCKER_TLS_CERTDIR=

# Redirect logs to a file
RUN sed -ri 's/exec "\$@\"/exec "\$@\" > \/var\/log\/docker.log 2>\&1/g' /usr/local/bin/dockerd-entrypoint.sh
RUN sed -ri 's/exec "\$@\"/exec "\$@\" > \/var\/log\/docker.log 2>\&1/g' /usr/local/bin/docker-entrypoint.sh
