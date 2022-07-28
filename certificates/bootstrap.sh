#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# CA certificate
echo -e "\nGenerating CA certificate ..."
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# Client certificates
## admin
echo -e "\nGenerating admin certificate ..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

## kubelets
./gen-kublet-client-cert.sh

## kube-controller-manager
echo -e "\nGenerating kube-controller-manager certificate ..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

## kube-proxy
echo -e "\nGenerating kube-proxy certificate ..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

## kube-scheduler
echo -e "\nGenerating kube-scheduler certificate ..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

# API server certificate
./gen-kubernetes-api-server-cert.sh

# Service Account key pair
echo -e "\nGenerating service account certificate ..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

# Distribute the certificates
## Workers
./copy-workers-certs.sh

## Controllers
./copy-controllers-certs.sh

echo -e "\nAll done!"