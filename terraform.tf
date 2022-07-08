terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.21.0"
    }
  }

  cloud {
    organization = "redouaneachouri"

    workspaces {
      name = "kubernetes-the-hard-way"
    }
  }
}