variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "kubernetes-the-hard-way"
}

variable "vpc_cidr_range" {
  description = "Private IPs range"
  type        = string
  default     = "10.240.0.0/16"
}

variable "private_cidr_range" {
  description = "Private IPs range"
  type        = string
  default     = "10.240.0.0/24"
}

variable "cluster_cidr_range" {
  description = "Kubernetes cluster CIDR range"
  type        = string
  default     = "10.200.0.0/16"
}

variable "ec2_ami_id" {
  description = "AMI ID for Ubuntu Server 20.04 LTS (HVM), SSD Volume Type"
  type        = string
  default     = "ami-012ae45a4a2d92750"
}

variable "ec2_access_key" {
  description = "Public key for EC2 access"
  type        = string
  sensitive   = true
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2wGxYMBRjrt9qpPQMvuiYRe+8UDg6yvjvL7XWJGtxIC0vEwwe1xsyByfIH2bfqPp1cDSV9Ed4vV+8QkqFYyJ3gT3XKfat5+yiCfEbjt2WdMpn7O0P+JX7HE12IgOFTSwGBywLRliXUiwj7/MW1eY8uRXv6ccnZTXh0yYUMenlDNXwtFO9pQwqAL2fipM5p0ub/4mDxDow/8P3N0Obu+MYZygx6zXHHgPv0ye1Jpra/REJ3QttdIhYZUFGrsvQLuxUXyJnPvsbQdJZET3XxmYv1qhQw0unlaBF47bjwCg1rSDUeLo7W+jSWfQbambnkmYaq54BVd9YsZmRs4sQ8+shKu7hyrn3NjPyuDZtmX2V897ihxZabPM7NaPzH/qHafo2asDrQNQVQahtMIvrkQEm7flQIKADZs5byWNDZVod8gyFXCGHSVsufgcV3fiX0kJ4gGLFR395DZsQLz6voa6JtSumUv3Sz+Zs++KAFdjpjT6kMb/4Rr5ox7sOfrNGZdE= redouane.achouri@C02DJ23LMD6R"
}

variable "kubernetes_controllers_count" {
  description = "Number of instances in the control cluster"
  type        = number
  default     = 3
}

variable "kubernetes_workers_count" {
  description = "Number of worker instances"
  type        = number
  default     = 3
}
