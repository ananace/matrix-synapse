FROM alpine:3.6

MAINTAINER Alexander Olofsson <ace@haxalot.com>

ARG SYNAPSE_VER=0.25.1

RUN set -eux \
    && apk add --no-cache \
      build-base ca-certificates python2-dev py2-pip su-exec \
      py2-psycopg2 py2-msgpack py2-psutil py2-openssl py2-yaml py-twisted \
      py2-netaddr py2-cffi py2-asn1 py2-asn1-modules py2-cryptography \
      py2-pillow py2-decorator py2-jinja2 py2-requests py2-simplejson py2-tz \
      py2-crypto py2-dateutil py2-service_identity \
    && pip install https://github.com/matrix-org/synapse/archive/v$SYNAPSE_VER.tar.gz \
    && rm -rf /root/.cache \
    && mkdir -p /synapse/config /synapse/data /synapse/keys \
    && addgroup -g 666 -S synapse \
    && adduser -u 666 -S -G synapse -h /synapse/config synapse

ADD log.yaml /synapse
ADD matrix-synapse.sh /matrix-synapse
VOLUME /synapse/config /synapse/data /synapse/keys

RUN chown -R synapse:synapse /synapse

EXPOSE 8008 8448
ENTRYPOINT [ "/matrix-synapse" ]
