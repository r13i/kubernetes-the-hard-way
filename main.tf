provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      "Name"    = var.project_name
      "Project" = var.project_name
    }
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_range
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_cidr_range
}

resource "aws_security_group" "security_group_allow_internal" {
  name        = "${var.project_name}-allow-internal"
  description = "Allow internal traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [var.private_cidr_range, var.cluster_cidr_range]
  }

  ingress {
    protocol    = "udp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [var.private_cidr_range, var.cluster_cidr_range]
  }

  ingress {
    protocol    = "icmp"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.private_cidr_range, var.cluster_cidr_range]
  }

  egress {
    protocol    = "-1" # All
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "security_group_allow_external" {
  name        = "${var.project_name}-allow-external"
  description = "Allow external traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 6443
    to_port     = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "icmp"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_key_pair" "access_key" {
  key_name   = "${var.project_name}-access-key"
  public_key = var.ec2_access_key
}
