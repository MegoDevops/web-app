output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "ecr_web_repository_url" {
  description = "ECR repository URL for web service"
  value       = module.ecr.web_repository_url  # ✅ CORRECT NAME
}

output "ecr_api_repository_url" {
  description = "ECR repository URL for api service"
  value       = module.ecr.api_repository_url  # ✅ CORRECT NAME
}

output "s3_terraform_bucket" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_elb_logs_bucket" {
  description = "S3 bucket for ELB logs"
  value       = module.s3.elb_logs_bucket  # ✅ CORRECT NAME
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = module.ec2.jenkins_public_ip
}

output "jenkins_url" {
  description = "Jenkins server URL"
  value       = "http://${module.ec2.jenkins_public_ip}:8080"
}