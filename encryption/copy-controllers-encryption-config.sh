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

# Check if the encryption config file exists
if [ ! -f "encryption-config.yaml" ]; then
  echo "The encryption configuration file does not exist at path '$PWD/encryption-config.yaml'"
  exit 1
fi

# See value of 'kubernetes_controllers_count' in variables.tf
CONTROLLERS_COUNT=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_controllers_count.value')

# Get controllers' public IPs
echo -e "\nReading controllers' public IPs ..."
CONTROLLERS_PUBLIC_IP=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_controllers_public_ip_addresses.value')

for i in $(seq 0 $(($CONTROLLERS_COUNT - 1))); do
  # Get each controller's public IPs
  PUBLIC_IP=$(echo "$CONTROLLERS_PUBLIC_IP" | jq -r ".\"controller-$i\"")

  echo -e "\nCopying the encryption configuration for controller-$i ($PUBLIC_IP) ..."

  scp \
    -i $EC2_ACCESS_KEY_PATH \
    -o "StrictHostKeyChecking=no" \
    encryption-config.yaml "ubuntu@$PUBLIC_IP:~/"
done

echo -e "\nDone!"