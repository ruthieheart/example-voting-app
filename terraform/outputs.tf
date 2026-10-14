output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Private API endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "aws_region" {
  description = "AWS region used by the deployment."
  value       = var.aws_region
}
