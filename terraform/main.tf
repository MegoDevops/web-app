# Create S3 bucket for Terraform state first
resource "aws_s3_bucket" "terraform_state" {
  bucket = "nti-project-bucket-backend-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  project_name        = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# ECR Module for container repositories
module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
}

# S3 Module for logs and backups
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
}

# EC2 Module for Jenkins
module "ec2" {
  source = "./modules/ec2"
  
  project_name   = var.project_name
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnet_ids
}


# EKS Module
module "eks" {
  source = "./modules/eks"
  
  project_name             = var.project_name
  private_subnets          = module.networking.private_subnet_ids
  public_subnets           = module.networking.public_subnet_ids  
  jenkins_security_group_id = module.ec2.jenkins_security_group_id  
  vpc_id                    = module.networking.vpc_id
  jenkins_iam_role_arn      = module.ec2.jenkins_iam_role_arn 
}



# IAM Role for Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}


# RDS Module for PostgreSQL database
module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  db_name            = "garden"
  db_user            = "postgres"
  db_password        = "password123!"
  private_subnets    = module.networking.private_subnet_ids

  db_security_group  = module.networking.db_sg_id
  jenkins_ec2_arn    = module.ec2.jenkins_arn
  backup_role_arn    = aws_iam_role.backup_role.arn
}
