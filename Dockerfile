FROM centos:7

MAINTAINER Alexander Olofsson <ace@haxalot.com>

ARG SYNAPSE_VER=0.27.2

RUN set -eux \
    && export LIBRARY_PATH=/lib:/usr/lib \
    && yum install -y epel-release \
    && yum upgrade -y \
    && yum install -y \
        git gcc make python-pip python-devel libffi-devel openssl-devel mailcap \
    && pip install -U pip \
    && pip install -U setuptools psycopg2 \
    && pip install https://github.com/matrix-org/synapse/archive/v$SYNAPSE_VER.tar.gz \
    && mkdir -p /synapse/config /synapse/data /synapse/keys /synapse/tls \
    && groupadd -r -g 666 synapse \
    && useradd -r -u 666 -g synapse -d /synapse/config -M synapse \
    && yum clean all \
    && yum autoremove -y \
        git gcc make python-devel openssl-devel \
    && yum clean -y all \
    && rm -rf /var/cache/yum/* /root/.cache/pip

ADD log.yaml /synapse
ADD matrix-synapse.sh /matrix-synapse
VOLUME /synapse/config /synapse/data /synapse/keys /synapse/tls

RUN chown -R synapse:synapse /synapse

EXPOSE 8008 8448
ENTRYPOINT [ "/matrix-synapse" ]
