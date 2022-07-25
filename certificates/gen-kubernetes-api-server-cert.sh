#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# Reserve the following IP for the API server
KUBERNETES_SERVER_PRIVATE_IP="10.32.0.1"
KUBERNETES_SERVER_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

# Get Kubernetes' public IP address
echo -e "\nReading Kubernetes' public IP and workers' private IPs ..."

KUBERNETES_PUBLIC_IP=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_public_ip_address.value')
CONTROLLERS_PRIVATE_IP_LIST=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_controllers_ip_addresses.value | to_entries | map(.value) | join(",")')

echo "KUBERNETES_PUBLIC_IP=$KUBERNETES_PUBLIC_IP"
echo "CONTROLLERS_PRIVATE_IP_LIST=$CONTROLLERS_PRIVATE_IP_LIST"

echo -e "\nGenerating certificate for Kubernetes API server ($KUBERNETES_PUBLIC_IP, $CONTROLLERS_PRIVATE_IP_LIST) ..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname="$KUBERNETES_SERVER_PRIVATE_IP","$CONTROLLERS_PRIVATE_IP_LIST","$KUBERNETES_PUBLIC_IP","$KUBERNETES_SERVER_HOSTNAMES","127.0.0.1" \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

echo -e "\nDone!"