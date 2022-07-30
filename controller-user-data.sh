Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

echo -e "\n[$(date)] Installing and bootstrapping ETCD"

ETCD_VER="v3.4.19"
ETCD_NAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
ETCD_PACKAGE_NAME="etcd-${ETCD_VER}-linux-amd64"
ETCD_INITIAL_CLUSTER="ETCD_INITIAL_CLUSTER_PLACEHOLDER"
ETCD_DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download

INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

HOME_UBUNTU="/home/ubuntu"

echo "ETCD_VER=$ETCD_VER"
echo "ETCD_NAME=$ETCD_NAME"
echo "ETCD_PACKAGE_NAME=$ETCD_PACKAGE_NAME"
echo "ETCD_INITIAL_CLUSTER=$ETCD_INITIAL_CLUSTER"

# Download and install ETCD to /usr/local/bin
echo -e "\nDownloading ETCD ..."

curl -sL ${ETCD_DOWNLOAD_URL}/${ETCD_VER}/${ETCD_PACKAGE_NAME}.tar.gz -o /tmp/${ETCD_PACKAGE_NAME}.tar.gz
tar xzf /tmp/${ETCD_PACKAGE_NAME}.tar.gz -C /tmp/
mv /tmp/${ETCD_PACKAGE_NAME}/etcd* /usr/local/bin

# Cleanup
rm -rf /tmp/${ETCD_PACKAGE_NAME}*

# Configure the ETCD
echo -e "\nConfiguring ETCD ..."

mkdir -p /etc/etcd /var/lib/etcd
chmod 700 /var/lib/etcd
cp "${HOME_UBUNTU}/ca.pem" "${HOME_UBUNTU}/kubernetes.pem" "${HOME_UBUNTU}/kubernetes-key.pem" /etc/etcd/

cat <<EOF | tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${ETCD_INITIAL_CLUSTER} \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo -e "\nStarting ETCD ..."
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd

echo -e "\nDone!"
--//--
