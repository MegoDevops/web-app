# Create RDS instance (PostgreSQL)
resource "aws_db_instance" "postgres" {
  identifier              = "${var.project_name}-rds"
  engine                  = "postgres"
  engine_version          = "15.5"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  db_name                 = var.db_name
  username                = var.db_user
  password                = var.db_password
  parameter_group_name    = "default.postgres13"
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false
  vpc_security_group_ids  = [var.db_security_group]
  db_subnet_group_name    = aws_db_subnet_group.rds.name

  tags = {
    Name = "${var.project_name}-rds"
  }
}

# Subnet group for RDS
resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnets
  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# Store credentials in Secrets Manager
resource "aws_secretsmanager_secret" "rds_secret" {
  name = "${var.project_name}/rds/credentials"
}

resource "aws_secretsmanager_secret_version" "rds_secret_value" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = var.db_user
    password = var.db_password
  })
}

# Backup plan for Jenkins EC2
resource "aws_backup_vault" "jenkins_vault" {
  name = "${var.project_name}-backup-vault"
}

resource "aws_backup_plan" "jenkins_backup_plan" {
  name = "${var.project_name}-backup-plan"

  rule {
    rule_name         = "daily-jenkins-backup"
    target_vault_name = aws_backup_vault.jenkins_vault.name
    schedule          = "cron(0 0 * * ? *)" # every day at midnight UTC
    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_selection" "jenkins_backup" {
  name         = "jenkins-backup-selection"
  iam_role_arn = var.backup_role_arn
  plan_id      = aws_backup_plan.jenkins_backup_plan.id

  resources = [
    var.jenkins_ec2_arn
  ]
}
