output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (or null)"
  value       = module.vpc.nat_gateway_id
}

output "eks_cluster_security_group_id" {
  description = "EKS control plane security group ID"
  value       = module.vpc.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "EKS worker nodes security group ID"
  value       = module.vpc.eks_nodes_security_group_id
} 