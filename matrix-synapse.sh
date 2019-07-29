#!/bin/sh -eu

APP="synapse.app.homeserver"
ARGS=""
GEN=""

case "${1:-start}" in
  # HS
  start|serve|synapse.app.homeserver)
    [ $# -gt 0 ] && shift
    ARGS="--config-path=/synapse/config"
    ;;

  # Worker
  synapse.* )
    APP="$1"
    shift

    if [ $# -lt 2 ]; then
      echo "You need to specify at least \`-c /worker-config.yaml\` if trying to run a worker"
      echo
      echo "More information can be found on https://github.com/matrix-org/synapse/blob/master/docs/workers.rst"
      exit 1
    fi
    ;;

  config)
    shift
    ARGS="--generate-config --keys-directory /synapse/keys --report-stats ${REPORT_STATS:-yes} -H ${SERVER_NAME}"
    GEN="true"

    fixup() {
      set +eu
      rm -rf /synapse/config/*.log.config
      
      (
      	mv /synapse/config/*.signing.key /synapse/keys/signing.key
      	mv /synapse/config/*.tls.dh /synapse/keys/dhparams.pem
      	mv /synapse/config/*.tls.crt /synapse/tls/tls.crt
      	mv /synapse/config/*.tls.key /synapse/tls/tls.key
      ) &> /dev/null

      sed -i /synapse/config/homeserver.yaml \
      	-e 's!^tls_certificate_path: .*!tls_certificate_path: "/synapse/tls/tls.crt"!' \
      	-e 's!^tls_private_key_path: .*!tls_private_key_path: "/synapse/tls/tls.key"!' \
      	-e 's!^tls_dh_params_path: .*!tls_dh_params_path: "/synapse/keys/dhparams.pem"!' \
      	-e 's!^signing_key_path: .*!signing_key_path: "/synapse/keys/signing.key"!' \
      	-e 's!^log_config: .*!log_config: "/synapse/config/log.yaml"!' \
      	-e 's!^media_store_path: .*!media_store_path: "/synapse/data/media"!' \
      	-e 's!^uploads_path: .*!uploads_path: "/synapse/data/uploads"!' \
      	-e 's!^web_client: True!web_client: False!'

      echo "Make sure to look through the generated homeserver yaml, check that everything looks correct before launching your Synapse."
      echo "If you need to generate keys, you can do so with the \`docker run ... ananace/matrix-synapse ... keys\` command."
    }
    trap fixup EXIT
    ;;

  keys)
    shift
    ARGS="--generate-keys --keys-directory /synapse/keys"
    ;;

  *)
    exec "$@"
    ;;
esac

if [ ! -f /synapse/config/homeserver.yaml ] && [ -z "$GEN" ]; then
  echo "Missing /synapse/config/homeserver.yaml, you need to generate a configuration before you can run the homeserver."
  echo
  echo "Try running with \`docker run ... -e SERVER_NAME=example.com ananace/matrix-synapse:... config\` to let it generate your configuration."
  exit 1
fi
 
if [ ! -e /synapse/config/log.yaml ]; then
  (
    set +eu
    cp /synapse/log.yaml /synapse/config || true
  )
fi

echo "Ensuring file ownership..."
(
  set +eu
  chown -R synapse:synapse /synapse/config /synapse/keys /synapse/tls || true
  chown -R synapse:synapse /synapse/data &
) > /dev/null 2>&1

if [ -n "${USE_JEMALLOC:-}" ]; then
  JEMALLOC="LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 "
fi

echo "> python -m $APP -c /synapse/config/homeserver.yaml $ARGS $*"
su synapse -s /bin/sh -c \
  "${JEMALLOC:-} python -B -m $APP -c /synapse/config/homeserver.yaml $ARGS $*"
