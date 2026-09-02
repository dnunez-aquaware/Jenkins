variable "aws_region" {
  description = "AWS region where the infrastructure will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used to identify the lab resources"
  type        = string
  default     = "jenkins-docker-lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to access EC2 through SSH"
  type        = string

  # Change this to your public IP:
  # 203.0.113.10/32
  default = "0.0.0.0/0"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "jenkins-docker-lab/nginx"
}