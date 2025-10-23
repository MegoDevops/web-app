output "jenkins_instance_id" {
  description = "Jenkins EC2 instance ID"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Jenkins public IP"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_security_group_id" {
  description = "Jenkins security group ID"
  value       = aws_security_group.jenkins.id
}