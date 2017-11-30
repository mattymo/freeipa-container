#!/bin/bash -x

decode_base64_url() {
  local len=$((${#1} % 4))
  local result="$1"
  if [ $len -eq 2 ]; then result="$1"'=='
  elif [ $len -eq 3 ]; then result="$1"'='
  fi
  echo "$result" | tr '_-' '/+' | openssl enc -d -base64
}

decode_jwt(){
   decode_base64_url $(echo -n $2 | cut -d "." -f $1) | jq .
}

is_expired(){
  payload=$(decode_jwt 2 "$1")
  expTime=$(echo $payload | jq .exp)
  curTime=$(date +%s)
  if [ "$curTime" -gt "$expTime" ]; then
    return 0
  else
    return 1
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "WARNING: This script should be sourced."
fi

KUBECTL=$(which --skip-alias kubectl)

#export g_k8s_debug=1

if [ -z "$SAB_K8S_UID" ]; then
  if [ -n "$EMAIL" ]; then
    SAB_K8S_UID=$EMAIL
  else
    echo -n "Enter your email address: "
    read SAB_K8S_UID
  fi
fi

if [ -z "$SAB_K8S_PWD" ]; then
  echo -n "Enter password for $SAB_K8S_UID: "
  read -s SAB_K8S_PWD
  echo
fi

DEFAULT_SAB_K8S_DEX_HOST=https://dex.core.svc.cluster.local
DEFAULT_SAB_K8S_DEX_WORKER_HOST=http://dex-worker.core.svc.cluster.local
if [ -z "$SAB_K8S_DEX_HOST" ]; then
  if [ -n "$DOMAINNAME" ]; then
    DEX_DOMAINNAME="core.svc.$(echo $DOMAINNAME | cut -d'.' -f3-)"
    SAB_K8S_DEX_HOST="https://dex.${DEX_DOMAINNAME}"
    SAB_K8S_DEX_WORKER_HOST="https://dex-worker.${DEX_DOMAINNAME}"
  else
    echo -n "Enter Dex hostname (example: https://dex.core.svc.cluster.local): "
    read SAB_K8S_DEX_HOST
    echo -n "Enter Dex Worker hostname (example: https://dex-worker.core.svc.cluster.local): "
    read SAB_K8S_DEX_WORKER_HOST
    # Set to default if not specified
    SAB_K8S_DEX_HOST=${SAB_K8S_DEX_HOST:-$DEFAULT_SAB_K8S_DEX_HOST}
    SAB_K8S_DEX_WORKER_HOST=${SAB_K8S_DEX_WORKER_HOST:-$DEFAULT_SAB_K8S_DEX_WORKER_HOST}
  fi
fi

export SAB_K8S_UID
export SAB_K8S_PWD
export SAB_K8S_DEX_HOST
export SAB_K8S_DEX_WORKER_HOST

# Only fetch token if it is not set or is expired
if [ -z "$JWT" ] || ! [[ "$JWT" =~ "^([A-Za-z0-9+/]{4}){2}" ]] || is_expired "$JWT"; then
  JWT=$(dex-k8s.sh dex-login)
  if [ $? -ne 0 ]; then
    echo "Login failed!"
    unset JWT
    return 1
  fi
  export JWT
fi

# Only write kubeconfig if JWT is missing
if ! grep -q "$JWT" ~/.kube/config 2>/dev/null; then
  $KUBECTL config set-credentials $SAB_K8S_UID --token="$JWT" > /dev/null
  $KUBECTL config set-cluster default --server=https://kubernetes.default --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt > /dev/null
  $KUBECTL config set-context default --cluster=default --user=$SAB_K8S_UID > /dev/null
  $KUBECTL config use-context default > /dev/null
fi
