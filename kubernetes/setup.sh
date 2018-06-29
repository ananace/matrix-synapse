#!/bin/bash

set -euo pipefail

VERBOSE=false
NOOP=false

usage() { echo -e "Uage: $0 [-hvn] [-- kubectl options]\n\n  -h  Display this text\n  -v  Enable verbose output\n  -n  Only print commands, don't run them"; }

run() {
  local CMD=$1
  shift
  local ARGS=$*

  set +e
  [ "$VERBOSE" == 'true' ] || [ "$NOOP" == 'true' ] && echo "> ${CMD} ${ARGS}" 1>&2
  [ "$NOOP" != 'true' ] && eval "${CMD} ${ARGS}"
  [ "$CMD" == "cat" ] && [[ ( "$VERBOSE" == 'true' || "$NOOP" == 'true' ) ]] && eval "${CMD} ${ARGS}"
  set -e
}

set +e
ARGS=$(getopt -o :hvn -n "$0" -- "$@")
[ $? -ne 0 ] && { echo "Failed to parse options."; usage; exit 1; }
set -e
eval set -- "$ARGS"

while true; do
  case "$1" in
    -v)
      VERBOSE=true
      shift
      ;;

    -n)
      NOOP=true
      shift
      ;;

    -h)
      usage
      exit 0
      ;;

    --)
      shift;
      break
      ;;

    *)
      echo "Unknown option -${OPTARG}"
      echo
      usage
      exit 1
      ;;
  esac
done

set +e
which docker &>/dev/null || (
  echo "This script currently requires docker to be installed on your local machine, sorry."
  exit 1
)
set -e

read -rp "Enter the server name of the Synapse instance: " SERVER_NAME
read -rp "Enter the namespace for the Matrix instance: " NAMESPACE

TEMP="$(mktemp -d)"
run cd "$TEMP"

echo "Generating configuration..."
run mkdir config tls keys
run docker run --rm \
    -v "$TEMP/config:/synapse/config" \
    -v "$TEMP/tls:/synapse/tls" \
    -v "$TEMP/keys:/synapse/keys" \
    -e "SERVER_NAME=$SERVER_NAME" \
       ananace/matrix-synapse config

run docker run --rm \
    -v "$TEMP/config:/synapse/config" \
    -v "$TEMP/tls:/synapse/tls" \
    -v "$TEMP/keys:/synapse/keys" \
    busybox chown "$(id -u):$(id -g)" -R /synapse
 
echo "Opening an editor against the configuration"
run "$EDITOR" "$TEMP/config/homeserver.yaml"

echo "Generating keys..."
run docker run --rm \
    -v "$TEMP/config:/synapse/config:ro" \
    -v "$TEMP/tls:/synapse/tls" \
    -v "$TEMP/keys:/synapse/keys" \
    -e "SERVER_NAME=$SERVER_NAME" \
       ananace/matrix-synapse keys

run docker run --rm \
    -v "$TEMP/config:/synapse/config" \
    -v "$TEMP/tls:/synapse/tls" \
    -v "$TEMP/keys:/synapse/keys" \
    busybox chown "$(id -u):$(id -g)" -R /synapse

read -rp "Press [Enter] to deploy "

set +e
run kubectl "$@" get namespace "$NAMESPACE" &> /dev/null || run kubectl "$@" create namespace "$NAMESPACE"
set -e
run kubectl --namespace="$NAMESPACE" "$@" create secret tls matrix-synapse-tls --cert="$TEMP/tls/*tls.crt" --key="$TEMP/tls/*tls.key"
run kubectl --namespace="$NAMESPACE" "$@" create secret generic matrix-synapse-keys --from-file=dhparams.pem="$TEMP/keys/dhparams.pem" --from-file=signing.key="$TEMP/keys/signing.key"
run kubectl --namespace="$NAMESPACE" "$@" create configmap matrix-synapse --from-file=homeserver.yaml="$TEMP/config/homeserver.yaml"

set +e
read -r -d '' DATA <<EOF
---
kind: Service
apiVersion: v1
metadata:
  labels:
    app: matrix-synapse
  name: matrix-synapse-replication
spec:
  ports:
    - name: replication
      protocol: TCP
      port: 9092
      targetPort: 9092
  selector:
    app: matrix-synapse
  type: ClusterIP
---
kind: Service
apiVersion: v1
metadata:
  labels:
    app: matrix-synapse
  name: matrix-synapse
spec:
  ports:
    - name: http
      protocol: TCP
      port: 8008
      targetPort: 8008
    - name: https
      protocol: TCP
      port: 8448
      targetPort: 8448
  selector:
    app: matrix-synapse
  type: ClusterIP
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: matrix-synapse
  labels:
    app: matrix-synapse
spec:
  selector:
    matchLabels:
      app: matrix-synapse
  template:
    metadata:
      labels:
        app: matrix-synapse
    spec:
      volumes:
        - name: matrix-synapse-data
          emptyDir: {}
        - name: matrix-synapse-tls
          secret:
            secretName: matrix-synapse-tls
        - name: matrix-synapse-keys
          secret:
            secretName: matrix-synapse-keys
        - name: matrix-synapse-config
          configMap:
            name: matrix-synapse-config
      containers:
        - name: matrix-synapse
          image: ananace/matrix-synapse:latest
          volumeMounts:
            - name: matrix-synapse-data
              mountPath: /synapse/data
            - name: matrix-synapse-config
              mountPath: /synapse/config
            - name: matrix-synapse-keys
              mountPath: /synapse/keys
            - name: matrix-synapse-tls
              mountPath: /synapse/tls
          env:
            - name: SYNAPSE_CACHE_FACTOR
              value: '0.01'
          resources:
            requests:
              memory: 250Mi
              cpu: 250m
            limits:
              memory: 4Gi
              cpu: 1
          livenessProbe:
            httpGet:
              path: /_matrix/client/versions
              port: 8008
              scheme: HTTP
          readinessProbe:
            httpGet:
              path: /_matrix/client/versions
              port: 8008
              scheme: HTTP
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/tls-acme: 'true'
  name: matrix-synapse
spec:
  rules:
  - host: $SERVER_NAME
    http:
      paths:
      - backend:
          serviceName: matrix-synapse
          servicePort: 8008
        path: /
  tls:
  - hosts:
    - $SERVER_NAME
    secretName: matrix-synapse-tls
---
EOF
set -e

echo "$DATA" | run kubectl --namespace="$NAMESPACE" "$@" create -f -

rm -r "$TEMP"
