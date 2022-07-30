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

KUBERNETES_PUBLIC_IP="KUBERNETES_PUBLIC_IP_PLACEHOLDER"
KUBERNETES_ETCD_SERVERS="KUBERNETES_ETCD_SERVERS_PLACEHOLDER"
CONTROLLERS_COUNT="CONTROLLERS_COUNT_PLACEHOLDER"
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

# Start ETCD
echo -e "\nStarting ETCD ..."
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd

echo -e "\n[$(date)] Installing and bootstrapping Kubernetes"

KUBERNETES_VER="v1.21.14"

echo "KUBERNETES_VER=${KUBERNETES_VER}"

# Download and install Kubernetes binaries to /usr/local/bin
echo -e "\nDownloading Kubernetes binaries ..."

mkdir -p /tmp/kubernetes-bin/
curl -sL https://dl.k8s.io/${KUBERNETES_VER}/bin/linux/amd64/kube-apiserver -o /tmp/kubernetes-bin/kube-apiserver
curl -sL https://dl.k8s.io/${KUBERNETES_VER}/bin/linux/amd64/kube-controller-manager -o /tmp/kubernetes-bin/kube-controller-manager
curl -sL https://dl.k8s.io/${KUBERNETES_VER}/bin/linux/amd64/kube-scheduler -o /tmp/kubernetes-bin/kube-scheduler
curl -sL https://dl.k8s.io/${KUBERNETES_VER}/bin/linux/amd64/kubectl -o /tmp/kubernetes-bin/kubectl

chmod +x /tmp/kubernetes-bin/*
mv /tmp/kubernetes-bin/* /usr/local/bin/

# Cleanup
rm -rf /tmp/kubernetes-bin/

# Configure the Kubernetes API server
echo -e "\nConfiguring Kubernetes API server ..."

mkdir -p /var/lib/kubernetes/

cp \
  "${HOME_UBUNTU}/ca.pem" \
  "${HOME_UBUNTU}/ca-key.pem" \
  "${HOME_UBUNTU}/kubernetes.pem" \
  "${HOME_UBUNTU}/kubernetes-key.pem" \
  "${HOME_UBUNTU}/service-account.pem" \
  "${HOME_UBUNTU}/service-account-key.pem" \
  "${HOME_UBUNTU}/encryption-config.yaml" \
  /var/lib/kubernetes/

cat <<EOF | tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=${CONTROLLERS_COUNT} \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=${KUBERNETES_ETCD_SERVERS} \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --runtime-config='api/all=true' \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-account-signing-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-account-issuer=https://${KUBERNETES_PUBLIC_IP}:6443 \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure the Kubernetes Controller Manager
echo -e "\nConfiguring Kubernetes Controller Manager ..."

mv "${HOME_UBUNTU}/kube-controller-manager.kubeconfig" /var/lib/kubernetes/

cat <<EOF | tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure the Kubernetes Scheduler
echo -e "\nConfiguring Kubernetes Scheduler ..."

mkdir -p /etc/kubernetes/config/
mv "${HOME_UBUNTU}/kube-scheduler.kubeconfig" /var/lib/kubernetes/

cat <<EOF | tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

cat <<EOF | tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start Kubernetes components
echo -e "\n Starting Kubernetes components ..."
systemctl daemon-reload
systemctl enable kube-apiserver kube-controller-manager kube-scheduler
systemctl start kube-apiserver kube-controller-manager kube-scheduler

echo -e "\nDone!"
--//--
