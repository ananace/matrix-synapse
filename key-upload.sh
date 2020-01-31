#!/bin/sh

set -euo pipefail

check_key() {
  set +e

  echo "Checking for existing signing key..."
  key=$(kubectl get secret $SECRET_NAME -o jsonpath="{.data['signing\.key']}" 2> /dev/null)
  [ $? -ne 0 ] && return 1
  [ -z "$key" ] && return 2
  return 0
}

create_key() {
  echo "Waiting for new signing key to be generated..."
  begin=$(date +%s)
  end=$((begin + 300)) # 5 minutes
  while true; do
    [ -f /synapse/keys/signing.key ] && return 0
    [ $(date +%s) -gt $end ] && return 1
    sleep 5
  done
}

store_key() {
  # TODO: Update/replace feature
  echo "Storing signing key in Kubernetes secret..."
  kubectl create secret generic $SECRET_NAME --from-file=signing.key=/synapse/keys/signing.key 2> /dev/null
}

if check_key; then
  echo "Key already in place, exiting."
  exit
fi

if !create_key; then
  echo "Timed out waiting for a signing key to appear."
  exit 1
fi

store_key
