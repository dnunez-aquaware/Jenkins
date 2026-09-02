output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.lab.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.lab.public_dns
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.nginx.repository_url
}