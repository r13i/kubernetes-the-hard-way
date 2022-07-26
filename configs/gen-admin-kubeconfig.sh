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

# Check if the admin's certificate and key files exist
if [[ ! -f "$CERTIFICATES_PATH/admin.pem" || ! -f "$CERTIFICATES_PATH/admin-key.pem" ]]; then
  echo "The admin certificate or key file does not exist at path '$CERTIFICATES_PATH/'"
  exit 1
fi

echo -e "\nGenerating Kubernetes configuration for admin ..."

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority="$CERTIFICATES_PATH/ca.pem" \
  --embed-certs=true \
  --server="https://127.0.0.1:6443" \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials "admin" \
  --client-certificate="$CERTIFICATES_PATH/admin.pem" \
  --client-key="$CERTIFICATES_PATH/admin-key.pem" \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user="admin" \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

echo -e "\nDone!"