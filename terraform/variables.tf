variable "aws_region" {
  description = "AWS region for the capstone infrastructure."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name prefix for capstone resources."
  type        = string
  default     = "voting-capstone"
}

variable "kubernetes_version" {
  description = "Kubernetes version requested for EKS."
  type        = string
  default     = "1.33"
}
