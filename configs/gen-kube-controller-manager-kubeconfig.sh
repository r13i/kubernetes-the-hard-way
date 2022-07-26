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

# Check if the kube-controller-manager's certificate and key files exist
if [[ ! -f "$CERTIFICATES_PATH/kube-controller-manager.pem" || ! -f "$CERTIFICATES_PATH/kube-controller-manager-key.pem" ]]; then
  echo "The kube-controller-manager certificate or key file does not exist at path '$CERTIFICATES_PATH/'"
  exit 1
fi

echo -e "\nGenerating Kubernetes configuration for kube-controller-manager ..."

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority="$CERTIFICATES_PATH/ca.pem" \
  --embed-certs=true \
  --server="https://127.0.0.1:6443" \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials "system:kube-controller-manager" \
  --client-certificate="$CERTIFICATES_PATH/kube-controller-manager.pem" \
  --client-key="$CERTIFICATES_PATH/kube-controller-manager-key.pem" \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user="system:kube-controller-manager" \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

echo -e "\nDone!"