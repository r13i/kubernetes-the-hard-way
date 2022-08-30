output "kubernetes_public_ip_address" {
  description = "Public EIP address of the Kubernetes cluster"
  value       = aws_eip.kubernetes_public_ip.public_ip
}

output "kubernetes_load_balancer_dns_name" {
  description = "Public DNS name of the Kubernetes cluster"
  value       = aws_lb.controllers_load_balancer.dns_name
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
