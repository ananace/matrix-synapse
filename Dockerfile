ARG SYNAPSE_VERSION="1.110.0"
FROM ghcr.io/element-hq/synapse:v${SYNAPSE_VERSION}

MAINTAINER Alexander Olofsson <ace@haxalot.com>

RUN set -eux \
 && mkdir -p /synapse/config/conf.d /synapse/data /synapse/keys /synapse/tls \
 && addgroup --system --gid 666 synapse \
 && adduser --system --uid 666 --ingroup synapse --home /synapse/data --disabled-password --no-create-home synapse \
 && chown -R synapse:synapse /synapse/config /synapse/data /synapse/keys /synapse/tls

ADD log.yaml /synapse
ADD matrix-synapse.sh /matrix-synapse
ADD key-upload.sh /key-upload

EXPOSE 8008/tcp 8448/tcp
ENTRYPOINT [ "/matrix-synapse" ]
