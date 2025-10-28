# Custom DB parameter group for better control
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.project_name}-postgres16-params"
  family = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  tags = {
    Name        = "${var.project_name}-postgres-params"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Create RDS instance (PostgreSQL) - SINGLE DEFINITION
resource "aws_db_instance" "postgres" {
  identifier              = "${var.project_name}-rds"
  engine                  = "postgres"
  engine_version          = "16.9"  # Fixed: 16.9 
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  db_name                 = var.db_name
  username                = var.db_user
  password                = var.db_password
  parameter_group_name    = aws_db_parameter_group.postgres.name  # Use custom parameter group
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false
  vpc_security_group_ids  = [var.db_security_group]
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  backup_retention_period = 7  # Added: Enable automated backups
  backup_window           = "02:00-03:00"  # Added: Backup window
  maintenance_window      = "sun:03:00-sun:04:00"  # Added: Maintenance window
  deletion_protection     = false  # Added: Set to true for production
  apply_immediately       = true  # Added: Apply changes immediately

  tags = {
    Name        = "${var.project_name}-rds"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Subnet group for RDS
resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnets
  
  tags = {
    Name        = "${var.project_name}-rds-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Store credentials in Secrets Manager
resource "aws_secretsmanager_secret" "rds_secret" {
  name = "${var.project_name}/rds/credentials"
  
  description = "RDS database credentials for ${var.project_name}"
  
  tags = {
    Name        = "${var.project_name}-rds-secret"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "rds_secret_value" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username             = var.db_user
    password             = var.db_password
    engine               = "postgres"
    host                 = aws_db_instance.postgres.address
    port                 = aws_db_instance.postgres.port
    dbname               = var.db_name
    dbInstanceIdentifier = aws_db_instance.postgres.identifier
  })
  
  depends_on = [aws_db_instance.postgres]
}

# Database connection details secret (separate from credentials)
resource "aws_secretsmanager_secret" "rds_connection" {
  name = "${var.project_name}/rds/connection"
  
  description = "RDS connection details for ${var.project_name}"
  
  tags = {
    Name        = "${var.project_name}-rds-connection"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "rds_connection_value" {
  secret_id = aws_secretsmanager_secret.rds_connection.id
  secret_string = jsonencode({
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    database = var.db_name
    endpoint = "${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}"
  })
  
  depends_on = [aws_db_instance.postgres]
}

# Backup plan for Jenkins EC2
resource "aws_backup_vault" "jenkins_vault" {
  name = "${var.project_name}-backup-vault"
  
  tags = {
    Name        = "${var.project_name}-backup-vault"
    Project     = var.project_name
    Environment = var.environment
  }
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
    
    enable_continuous_backup = true  # Added: Enable continuous backups
  }

  tags = {
    Name        = "${var.project_name}-backup-plan"
    Project     = var.project_name
    Environment = var.environment
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

# CloudWatch alarms for RDS monitoring
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = var.alarm_notification_arn != "" ? [var.alarm_notification_arn] : []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }

  tags = {
    Name        = "${var.project_name}-rds-cpu-alarm"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2147483648" # 2GB in bytes
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = var.alarm_notification_arn != "" ? [var.alarm_notification_arn] : []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }

  tags = {
    Name        = "${var.project_name}-rds-storage-alarm"
    Project     = var.project_name
    Environment = var.environment
  }
}