# kubernetes-the-hard-way

Using Terraform with AWS for learning
[Kubernetes the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way).

## Run

### Setup organization and workspace

In `terraform.tf`, set your [Terraform Cloud](https://cloud.hashicorp.com/products/terraform) organization
and workspace name:

```terraform
cloud {
  organization = "<your organization name>"

  workspaces {
    name = "<your workspace name>"
  }
}
```

#### Provide AWS credentials (alternative)

Alternatively to [setting up Terraform Cloud](#setup-organization-and-workspace), please refer to the
[Authentication and Configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
section of the Terraform AWS Provider documentation.

### Generate access key pair

> Requirements: [ssh-keygen](https://en.wikipedia.org/wiki/Ssh-keygen)

Following the instructions in the AWS documentation
[Create a key pair using a third-party tool and import the public key to Amazon EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws),
we generate a public/private key pair using `ssh-keygen`:

```bash
# Length = 4096
# Format = PEM
# Type = RSA
# Filename = access-key
# No password
ssh-keygen -b 4096 -m PEM -t rsa -N "" -f access-key
```

and import it to EC2 using Terraform:

```terraform
# main.tf

...
resource "aws_key_pair" "access_key" {
  key_name   = "<your access key name>"
  public_key = "<content of generated file access-key.pub>"
}
```

### Create the infrastructure

> Requirements: [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)

```bash
# Login to you Terraform Cloud
terraform login

# Then apply the infrastructure to your account
terraform apply
```

### Generate TLS certificates

> Requirements: [Cloudflare's CFSSL](https://github.com/cloudflare/cfssl)

> The following steps are condensed in the [bootstrap.sh](./certificates/bootstrap.sh) script for quick setup.

After creating the infrastructure in the previous step [Create the infrastructure](#create-the-infrastructure), make
sure to `cd` into `certificates/`, then run the following:

1. **CA certificate**: Use the provided CSR config file to generate a CA certificate and private key.

```bash
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

2. **Client certificates**: Generate a client certificate and private key for each Kubernetes component.

  * The `admin` client certificate and private key:

```bash
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```

  * The Kubelet client certificates and private keys:

```bash
# Examine the gen script then execute it
./gen-kublet-client-cert.sh

# Result
worker-0.pem
worker-0-key.pem
# same for all workers 0, 1, ...
```

  * The `kube-controller-manager` client certificate and private key:

```bash
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
```

  * The `kube-proxy` client certificate and private key:

```bash
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
```

  * The `kube-scheduler` client certificate and private key:

```bash
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
```

3. **Kubernetes API server certificate**: The project's static IP (AWS Elastic IP) will be added to the list of SANs
for the Kubernetes API server certificate to ensure the certificate is validated by remote clients.

```bash
# Examine the gen script then execute it
./gen-kubernetes-api-server-cert.sh
```

4. **Service Account key pair**: The Kubernetes Controller Manager leverages a key pair to generate and sign
service account tokens as described in the
[managing service accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)
documentation.

```bash
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account
```

#### Distribute the client and server certificates

> Requirements: [scp](https://en.wikipedia.org/wiki/Secure_copy_protocol),
[Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)

We will use the access key `access-key.pem` created in the previous step
[Generate access key pair](#generate-access-key-pair) to copy the certificates to the host instances via SSH.

Make sure to `cd` into `certificates/`, then run the following:

  * Certificates and private keys to the worker instances:

```bash
# Examine the copy script then execute it
# You can provide the path to your EC2 access key if it is different from access-key.pem at the project root directory
./copy-workers-certs.sh [path-to-access-key.pem]
```

  * Certificates and private keys to the controller instances:

```bash
# Examine the copy script then execute it
# You can provide the path to your EC2 access key if it is different from access-key.pem at the project root directory
./copy-controllers-certs.sh [path-to-access-key.pem]
```

### Generate Kubernetes configuration files for authentication

> Requirements: [kubectl](https://kubernetes.io/docs/tasks/tools/),
[Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)

We will generate the Kubernetes configuration files that enable the Kubernetes clients to locate and authenticate
to the Kubernetes API servers.

Make sure to `cd` into `configs/`, then run the following:

  * The Kubelets configuration files:

```bash
# Examine the gen script then execute it
./gen-kubelets-kubeconfig.sh
```

  * The `kube-proxy` configuration file:

```bash
# Examine the gen script then execute it
./gen-kube-proxy-kubeconfig.sh
```

  * The `kube-controller-manager` configuration file:

```bash
# Examine the gen script then execute it
./gen-kube-controller-manager-kubeconfig.sh
```

  * The `kube-scheduler` configuration file:

```bash
# Examine the gen script then execute it
./gen-kube-scheduler-kubeconfig.sh
```

  * The `admin` configuration file:

```bash
# Examine the gen script then execute it
./gen-admin-kubeconfig.sh
```

#### Distribute the Kubernetes configuration files

> Requirements: [scp](https://en.wikipedia.org/wiki/Secure_copy_protocol),
[Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)

We will use the access key `access-key.pem` created in the previous step
[Generate access key pair](#generate-access-key-pair) to copy the Kubernetes configuration files to the
host instances via SSH.

Make sure to `cd` into `configs/`, then run the following:

  * Kubernetes configuration files to the worker instances:

```bash
# Examine the copy script then execute it
# You can provide the path to your EC2 access key if it is different from access-key.pem at the project root directory
./copy-workers-kubeconfig.sh [path-to-access-key.pem]
```

  * Kubernetes configuration files to the controller instances:

```bash
# Examine the copy script then execute it
# You can provide the path to your EC2 access key if it is different from access-key.pem at the project root directory
./copy-controllers-kubeconfig.sh [path-to-access-key.pem]
```

### Generate the Data Encryption config and key

We will generate the encryption key and config used by Kubernetes to encrypt secrets.

Make sure to `cd` into `encryption/`, then run the following:

```bash
# Generate a key
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# Create a config file
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: $ENCRYPTION_KEY
      - identity: {}
EOF
```

#### Distribute the encryption configuration file

> Requirements: [scp](https://en.wikipedia.org/wiki/Secure_copy_protocol),
[Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)

We will use the access key `access-key.pem` created in the previous step
[Generate access key pair](#generate-access-key-pair) to copy the encryption configuration file to the
host instances via SSH.

Make sure to `cd` into `encryption/`, then run the following:

```bash
# Examine the copy script then execute it
# You can provide the path to your EC2 access key if it is different from access-key.pem at the project root directory
./copy-controllers-encryption-config.sh [path-to-access-key.pem]
```

### Bootstrapping the ETCD cluster and Kubernetes components

From the root project directory, we will set the controller instances to restart with a
[user-data script](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) that contains all the
instructions to download, configure, and start ETCD and the Kubernetes components on every controller instance.

The user data file [controller-user-data.sh](./controller-user-data.sh) contains a first part that instructs
[cloud-init](https://cloudinit.readthedocs.io/en/latest/topics/datasources/ec2.html)
to run the script on restart (default is to run on initial launch). See this AWS tutorial for more details:
- [How can I utilize user data to automatically run a script with every restart of my Amazon EC2 Linux instance?](https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/)

ETCD requires a mapping of hosts that are in the cluster `<controller-i> -> https://<host-i-private-ip>:2380`. The
steps below show you how to generate this mapping and replace it in the user data script so that it's available
to ETCD (the variable `ETCD_INITIAL_CLUSTER` contains initially a placeholder value).

Same thing for the parameters for the Kubernetes API server, it requires a few parameters that will be set by
fetching the configuration from Terraform and replacing placeholders in the user data script.

To bootstrap the ETCD and Kubernetes cluster, run the following:

```bash
# Generate a comma-separated list of ETCD cluster mappings <controller-i> -> https://<host-i-private-ip>:2380
ETCD_INITIAL_CLUSTER=$(terraform output -json | jq -r '.kubernetes_controllers_private_ip_addresses.value | to_entries | map("\(.key)=https://\(.value):2380") | join(",")')
KUBERNETES_ETCD_SERVERS=$(terraform output -json | jq -r '.kubernetes_controllers_private_ip_addresses.value | to_entries | map("https://\(.value):2379") | join(",")')

# Replace in the user data script
sed -i "s+ETCD_INITIAL_CLUSTER_PLACEHOLDER+$ETCD_INITIAL_CLUSTER+" controller-user-data.sh
sed -i "s+KUBERNETES_ETCD_SERVERS_PLACEHOLDER+$KUBERNETES_ETCD_SERVERS+" controller-user-data.sh
## macOS users need to add a "" after -i
sed -i "" "s+ETCD_INITIAL_CLUSTER_PLACEHOLDER+$ETCD_INITIAL_CLUSTER+" controller-user-data.sh
sed -i "" "s+KUBERNETES_ETCD_SERVERS_PLACEHOLDER+$KUBERNETES_ETCD_SERVERS+" controller-user-data.sh

# Get the Kubernetes public IP
KUBERNETES_PUBLIC_IP=$(terraform output --json | jq -r '.kubernetes_public_ip_address.value')

# Replace in the user data script
sed -i "s+KUBERNETES_PUBLIC_IP_PLACEHOLDER+$KUBERNETES_PUBLIC_IP+" controller-user-data.sh
## macOS users need to add a "" after -i
sed -i "" "s+KUBERNETES_PUBLIC_IP_PLACEHOLDER+$KUBERNETES_PUBLIC_IP+" controller-user-data.sh

# Get the count of Kubernetes controllers
CONTROLLERS_COUNT=$(terraform output --json | jq -r '.kubernetes_controllers_count.value')

# Replace in the user data script
sed -i "s+CONTROLLERS_COUNT_PLACEHOLDER+$CONTROLLERS_COUNT+" controller-user-data.sh
## macOS users need to add a "" after -i
sed -i "" "s+CONTROLLERS_COUNT_PLACEHOLDER+$CONTROLLERS_COUNT+" controller-user-data.sh


# Apply the infrastructure to ship the user data script to controller instances (without replacing the instances)
# Make sure to verify the parameters have been correctly set in controller-user-data.sh
terraform apply -var "install_controller_user_data=true"
```

#### Verification

```bash
# SSH into one of the controller instances
ssh -i access-key.pem ubuntu@<controller public address>

# Run
ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem
```
