#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# See value of 'kubernetes_workers_count' in variables.tf
WORKERS_COUNT=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_workers_count.value')

# Get workers' private and public IPs
echo -e "\nReading workers' private and public IPs ..."
WORKERS_PRIVATE_IP=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_workers_private_ip_addresses.value')
WORKERS_PUBLIC_IP=$(terraform -chdir=./.. output --json | jq -r '.kubernetes_workers_public_ip_addresses.value')

for i in $(seq 0 $(($WORKERS_COUNT - 1))); do
  # Create a CSR for each worker
  cat > "worker-$i-csr.json" <<EOF
{
  "CN": "system:node:worker-$i",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "SE",
      "L": "Stockholm",
      "ST": "Stockholm",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way"
    }
  ]
}
EOF

  # Get each worker's private and public IPs
  PRIVATE_IP=$(echo "$WORKERS_PRIVATE_IP" | jq -r ".\"worker-$i\"")
  PUBLIC_IP=$(echo "$WORKERS_PUBLIC_IP" | jq -r ".\"worker-$i\"")

  echo -e "\nGenerating certificate for worker-$i ($PRIVATE_IP, $PUBLIC_IP) ..."

  # Generate a certificate
  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname="worker-$i","$PRIVATE_IP","$PUBLIC_IP" \
    -profile=kubernetes \
    "worker-$i-csr.json" | cfssljson -bare "worker-$i"

done

echo -e "\nDone!"