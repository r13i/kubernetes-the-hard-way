#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# Get path to the EC2 access key and verify it exists
EC2_ACCESS_KEY_PATH=${1:-"../access-key.pem"}
echo "EC2_ACCESS_KEY_PATH=$EC2_ACCESS_KEY_PATH"

if [ ! -f "$EC2_ACCESS_KEY_PATH" ]; then
  echo "The EC2 access key does not exist at path '$PWD/$EC2_ACCESS_KEY_PATH'"
  exit 1
fi

# Check if the kube-proxy config file exists
if [ ! -f "kube-proxy.kubeconfig" ]; then
  echo "The kube-proxy configuration file does not exist at path '$PWD/kube-proxy.kubeconfig'"
  exit 1
fi

# See value of 'kubernetes_workers_count' in variables.tf
WORKERS_COUNT=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_workers_count.value')

# Get workers' public IPs
echo -e "\nReading workers' public IPs ..."
WORKERS_PUBLIC_IP=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_workers_public_ip_addresses.value')

for i in $(seq 0 $(($WORKERS_COUNT - 1))); do
  # Check if the worker's kubeconfig file exists
  if [ ! -f "worker-$i.kubeconfig" ]; then
    echo "The worker-$i kubeconfig file does not exist at path '$PWD/'"
    exit 1
  fi

  # Get each worker's public IPs
  PUBLIC_IP=$(echo "$WORKERS_PUBLIC_IP" | jq -r ".\"worker-$i\"")

  echo -e "\nCopying kubeconfigs for worker-$i ($PUBLIC_IP) ..."

  scp \
    -i $EC2_ACCESS_KEY_PATH \
    -o "StrictHostKeyChecking=no" \
    kube-proxy.kubeconfig "worker-$i.kubeconfig" "ubuntu@$PUBLIC_IP:~/"
done

echo -e "\nDone!"