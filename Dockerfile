ARG SYNAPSE_VERSION="1.15.0"
FROM matrixdotorg/synapse:v${SYNAPSE_VERSION}

MAINTAINER Alexander Olofsson <ace@haxalot.com>

RUN set -eux \
    && mkdir -p /synapse/config/conf.d /synapse/data /synapse/keys /synapse/tls \
    && addgroup -Sg 666 synapse \
    && adduser -Su 666 -G synapse -h /synapse/data -DH synapse \
    && chown -R synapse:synapse /synapse/config /synapse/data /synapse/keys /synapse/tls

ADD log.yaml /synapse
ADD matrix-synapse.sh /matrix-synapse
ADD key-upload.sh /key-upload

EXPOSE 8008/tcp 8448/tcp
ENTRYPOINT [ "/matrix-synapse" ]
