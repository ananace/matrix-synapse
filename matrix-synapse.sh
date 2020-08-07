#!/bin/sh -eu

APP="synapse.app.homeserver"
ARGS=""
GEN=""

case "${1:-start}" in
  # HS
  start|serve|synapse.app.homeserver)
    [ $# -gt 0 ] && shift
    ;;

  # Worker
  synapse.* )
    APP="$1"
    shift

    if [ $# -lt 2 ]; then
      echo "You need to specify at least \`-c /worker-config.yaml\` if trying to run a worker"
      echo
      echo "More information can be found on https://github.com/matrix-org/synapse/blob/master/docs/workers.md"
      exit 1
    fi
    ;;

  *)
    exec "$@"
    ;;
esac

if [ ! -f /synapse/config/homeserver.yaml ] && [ -z "$GEN" ]; then
  echo "Missing /synapse/config/homeserver.yaml, you need to generate and supply a configuration before you can run the homeserver."
  exit 1
fi
 
# XXX: Might be suitable to read all config from tmp path, for envvar support on read-only root
if [ ! -e /synapse/config/log.yaml ]; then
  if touch /synapse/config/log.yaml 2>/dev/null; then
    (
      set +eu
      cp /synapse/log.yaml /synapse/config/log.yaml || true
    )
  else
    echo "Warning, no log config was specified, and the init script is not allowed to write one."
    echo "You should manually insert the log config into your config folder;"
    echo
    cat /synapse/log.yaml
    echo
  fi
fi

if [ $(id -u) -eq 0 ]; then
  # TODO: Avoid doing this on every boot as well
  echo "Running as root, ensuring file ownership..."
  (
    set +eu
    chown -R synapse:synapse /synapse/config /synapse/keys /synapse/tls || true
    chown -R synapse:synapse /synapse/data &
  ) > /dev/null 2>&1
fi

if [ -n "${USE_JEMALLOC:-}" ]; then
  export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
fi

if [ -d '/synapse/config/conf.d' ]; then
  ARGS="-c /synapse/config/conf.d $ARGS"
fi

command_str="python"
args_str="-B -m $APP -c /synapse/config/homeserver.yaml $ARGS $*"

echo "> $command_str $args_str"
if [ $(id -u) -eq 0 ]; then
  exec su synapse -s /bin/sh -c "$command_str $args_str"
else
  exec $command_str $args_str
fi
