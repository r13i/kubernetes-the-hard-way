output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.subnet.id
}

output "security_group_allow_internal_id" {
  description = "ID of the internal traffic security group"
  value       = aws_security_group.security_group_allow_internal.id
}

output "security_group_allow_external_id" {
  description = "ID of the external traffic security group"
  value       = aws_security_group.security_group_allow_external.id
}

output "access_key_name" {
  description = "EC2 access key name"
  value       = aws_key_pair.access_key.key_name
}

output "kubernetes_public_ip_address" {
  description = "Public EIP address of the Kubernetes cluster"
  value       = aws_eip.kubernetes_public_ip.public_ip
}

output "kubernetes_controllers_private_ip_addresses" {
  description = "Private IP addresses of Kubernetes control plane"
  value       = { for c in aws_instance.kubernetes_controllers : c.tags.Name => c.private_ip }
}

output "kubernetes_controllers_public_ip_addresses" {
  description = "Public IP addresses of Kubernetes control plane"
  value       = { for c in aws_instance.kubernetes_controllers : c.tags.Name => c.public_ip }
}

output "kubernetes_workers_private_ip_addresses" {
  description = "Private IP addresses of Kubernetes workers"
  value       = { for c in aws_instance.kubernetes_workers : c.tags.Name => c.private_ip }
}

output "kubernetes_workers_public_ip_addresses" {
  description = "Public IP addresses of Kubernetes workers"
  value       = { for c in aws_instance.kubernetes_workers : c.tags.Name => c.public_ip }
}

output "kubernetes_controllers_count" {
  description = "Count of the Kubernetes controllers"
  value       = var.kubernetes_controllers_count
}

output "kubernetes_workers_count" {
  description = "Count of the Kubernetes workers"
  value       = var.kubernetes_workers_count
}
