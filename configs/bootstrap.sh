#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# Generate the kubernetes configuration files
## Kubelets configuration
echo -e "\nGenerating Kubelets configuration ..."
./gen-kubelets-kubeconfig.sh

## kube-proxy configuration
echo -e "\nGenerating kube-proxy configuration ..."
./gen-kube-proxy-kubeconfig.sh

## kube-controller-manager configuration
echo -e "\nGenerating kube-controller-manager configuration ..."
./gen-kube-controller-manager-kubeconfig.sh

## kube-scheduler configuration
echo -e "\nGenerating kube-scheduler configuration ..."
./gen-kube-scheduler-kubeconfig.sh

## admin configuration
echo -e "\nGenerating admin configuration ..."
./gen-admin-kubeconfig.sh

# Distributing the kubeconfig files
## Workers
./copy-workers-kubeconfig.sh

## Controllers
./copy-controllers-kubeconfig.sh
