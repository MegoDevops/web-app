variable "project_name" {}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
variable "private_subnets" {
  type = list(string)
}
variable "db_security_group" {}
variable "jenkins_ec2_arn" {}
variable "backup_role_arn" {}
