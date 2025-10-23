output "web_repository_url" {
  description = "ECR repository URL for web service"
  value       = aws_ecr_repository.web.repository_url
}

output "api_repository_url" {
  description = "ECR repository URL for api service"
  value       = aws_ecr_repository.api.repository_url
}