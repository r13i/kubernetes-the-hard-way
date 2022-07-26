#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# Get path to the TLS certificates and verify it exists
CERTIFICATES_PATH=${1:-"../certificates"}
echo "CERTIFICATES_PATH=$CERTIFICATES_PATH"

if [ ! -d "$CERTIFICATES_PATH" ]; then
  echo "The TLS certificates directory does not exist at path '$PWD/$CERTIFICATES_PATH'"
  exit 1
fi

# Check if the CA certificate file exists
if [ ! -f "$CERTIFICATES_PATH/ca.pem" ]; then
  echo "The CA certificate file does not exist at path '$CERTIFICATES_PATH/ca.pem'"
  exit 1
fi

# See value of 'kubernetes_workers_count' in variables.tf
WORKERS_COUNT=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_workers_count.value')

# Get Kubernetes' public IP address
KUBERNETES_PUBLIC_IP=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_public_ip_address.value')
echo "KUBERNETES_PUBLIC_IP=$KUBERNETES_PUBLIC_IP"

for i in $(seq 0 $(($WORKERS_COUNT - 1))); do
  # Check if the worker's certificate and key files exist
  if [[ ! -f "$CERTIFICATES_PATH/worker-$i.pem" || ! -f "$CERTIFICATES_PATH/worker-$i-key.pem" ]]; then
    echo "The worker-$i certificate or key file does not exist at path '$CERTIFICATES_PATH/'"
    exit 1
  fi

  echo -e "\nGenerating Kubernetes configuration for worker-$i ..."

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority="$CERTIFICATES_PATH/ca.pem" \
    --embed-certs=true \
    --server="https://${KUBERNETES_PUBLIC_IP}:6443" \
    --kubeconfig="worker-$i.kubeconfig"

  kubectl config set-credentials "system:node:worker-$i" \
    --client-certificate="$CERTIFICATES_PATH/worker-$i.pem" \
    --client-key="$CERTIFICATES_PATH/worker-$i-key.pem" \
    --embed-certs=true \
    --kubeconfig="worker-$i.kubeconfig"

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user="system:node:worker-$i" \
    --kubeconfig="worker-$i.kubeconfig"

  kubectl config use-context default --kubeconfig="worker-$i.kubeconfig"
done

echo -e "\nDone!"