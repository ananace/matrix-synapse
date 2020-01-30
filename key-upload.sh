#!/bin/sh

set -euo pipefail

check_key() {
  echo "Checking for existing signing key..."
  kubectl get secret $SECRET_NAME 2> /dev/null
  return $?
}

create_key() {
  echo "Waiting for new signing key to be generated..."
  begin=$(date +%s)
  end=$((begin + 300)) # 5 minutes
  while true; do
    [ -f /synapse/keys/*.signing.key ] && return 0
    [ $(date +%s) -gt $end ] && return 1
    sleep 5
  done
}

store_key() {
  echo "Storing signing key in Kubernetes secret..."
  kubectl create secret generic $SECRET_NAME --from-file=signing.key=/synapse/keys/*.signing.key 2> /dev/null
}

check_key && exit

create_key
store_key
