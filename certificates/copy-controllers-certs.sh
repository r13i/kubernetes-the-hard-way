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

declare -a FILES_LIST=(
  "ca.pem"
  "ca-key.pem"
  "kubernetes.pem"
  "kubernetes-key.pem"
  "service-account.pem"
  "service-account-key.pem"
)

FILES=""

# Check if the CA and API server and service-account certificates and keys files exist
for file in "${FILES_LIST[@]}"; do
  if [ ! -f $file ]; then
    echo "The file '$file' does not exist at path '$PWD/'"
    exit 1
  else
    FILES="$FILES $file"
  fi
done

# See value of 'kubernetes_controllers_count' in variables.tf
CONTROLLERS_COUNT=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_controllers_count.value')

# Get controllers' public IPs
echo -e "\nReading controllers' public IPs ..."
CONTROLLERS_PUBLIC_IP=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_controllers_public_ip_addresses.value')

for i in $(seq 0 $(($CONTROLLERS_COUNT - 1))); do
  # Get each controller's public IPs
  PUBLIC_IP=$(echo "$CONTROLLERS_PUBLIC_IP" | jq -r ".\"controller-$i\"")

  echo -e "\nCopying certificates for controller-$i ($PUBLIC_IP) ..."

  scp \
    -i $EC2_ACCESS_KEY_PATH \
    -o "StrictHostKeyChecking=no" \
    $FILES "ubuntu@$PUBLIC_IP:~/"
done

echo -e "\nDone!"