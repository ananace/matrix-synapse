FROM debian:jessie

MAINTAINER Alexander Olofsson <ace@haxalot.com>

RUN apt-get update -yqq \
    && apt-get install curl ca-certificates apt-transport-https -yqq --no-install-recommends \
    && curl https://matrix.org/packages/debian/repo-key.asc | apt-key add - \
    && echo "deb http://matrix.org/packages/debian/ jessie main" > /etc/apt/sources.list.d/synapse.list \
    && apt-get update -yqq \
    && apt-get install matrix-synapse python-matrix-synapse-ldap3 python-psycopg2 -yqq --no-install-recommends \
    && apt-get autoclean -yqq \
    && rm -rf /var/lib/apt/

ADD matrix-synapse.sh /usr/local/bin/matrix-synapse

EXPOSE 8008 8448
ENTRYPOINT [ "/usr/local/bin/matrix-synapse" ]
