resource "aws_s3_bucket" "elb_logs" {
  bucket = "${var.project_name}-elb-logs-${random_id.s3_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "elb_logs" {
  bucket = aws_s3_bucket.elb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "elb_logs" {
  bucket = aws_s3_bucket.elb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "random_id" "s3_suffix" {
  byte_length = 4
}