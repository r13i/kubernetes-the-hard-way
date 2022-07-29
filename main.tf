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
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_cidr_range
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}
resource "aws_security_group" "security_group_allow_internal" {
  name        = "${var.project_name}-allow-internal"
  description = "Allow internal traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow TCP on all ports"
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [var.private_cidr_range, var.cluster_cidr_range]
  }

  ingress {
    description = "Allow UDP on all ports"
    protocol    = "udp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [var.private_cidr_range, var.cluster_cidr_range]
  }

  ingress {
    description = "Allow ICMP ECHO (ping) traffic"
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.private_cidr_range, var.cluster_cidr_range]
  }

  egress {
    description = "Allow all egress traffic"
    protocol    = "-1"
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
    description = "Allow SSH from any source"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow custom HTTPS from any source"
    protocol    = "tcp"
    from_port   = 6443
    to_port     = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ICMP ECHO (ping) traffic from any source"
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "kubernetes_public_ip" {
  vpc = true
}

resource "aws_key_pair" "access_key" {
  key_name   = "${var.project_name}-access-key"
  public_key = var.ec2_access_key
}

resource "aws_instance" "kubernetes_controllers" {
  for_each = toset(formatlist("%d", range(var.kubernetes_controllers_count)))

  ami           = var.ec2_ami_id
  instance_type = "t3.micro"

  private_ip = "10.240.0.1${each.value}"
  subnet_id  = aws_subnet.subnet.id
  vpc_security_group_ids = [
    aws_security_group.security_group_allow_internal.id,
    aws_security_group.security_group_allow_external.id,
  ]

  associate_public_ip_address = true
  key_name                    = aws_key_pair.access_key.key_name

  user_data_replace_on_change = false
  user_data                   = var.install_controller_user_data ? "${file("controller-user-data.sh")}" : null

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }

  tags = {
    "Name" = "controller-${each.value}"
    "type" = "controller"
  }
}

resource "aws_instance" "kubernetes_workers" {
  for_each = toset(formatlist("%d", range(var.kubernetes_workers_count)))

  ami           = var.ec2_ami_id
  instance_type = "t3.micro"

  private_ip = "10.240.0.2${each.value}"
  subnet_id  = aws_subnet.subnet.id
  vpc_security_group_ids = [
    aws_security_group.security_group_allow_internal.id,
    aws_security_group.security_group_allow_external.id,
  ]

  associate_public_ip_address = true
  key_name                    = aws_key_pair.access_key.key_name

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }

  tags = {
    "Name"     = "worker-${each.value}"
    "type"     = "worker"
    "pod-cidr" = "10.200.${each.value}.0/24"
  }
}
