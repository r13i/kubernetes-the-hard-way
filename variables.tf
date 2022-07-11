variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "kubernetes-the-hard-way"

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

}