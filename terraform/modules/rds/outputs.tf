output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds_secret.arn
}
