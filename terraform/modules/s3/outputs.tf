output "elb_logs_bucket" {
  description = "S3 bucket for ELB logs"
  value       = aws_s3_bucket.elb_logs.bucket
}
