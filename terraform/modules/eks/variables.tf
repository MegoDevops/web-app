variable "project_name" {
  description = "Project name"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet IDs for EKS API endpoint"
  type        = list(string)
}

variable "jenkins_security_group_id" {
  description = "Jenkins security group ID for EKS access"
  type        = string
}


variable "vpc_id" {
  description = "VPC ID for EKS cluster"
  type        = string
}

variable "jenkins_iam_role_arn" {
  description = "Jenkins IAM role ARN for EKS access"
  type        = string
}