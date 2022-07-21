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
