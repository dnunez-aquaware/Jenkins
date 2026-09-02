
# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

resource "aws_vpc" "lab" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "jenkins-docker-lab-vpc"
  }
}

# ---------------------------------------------------------
# Public Subnet
# ---------------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "jenkins-docker-lab-public-subnet"
  }
}

# ---------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "jenkins-docker-lab-igw"
  }
}

# ---------------------------------------------------------
# Route Table
# ---------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }

  tags = {
    Name = "jenkins-docker-lab-public-rt"
  }
}

# ---------------------------------------------------------
# Route Table Association
# ---------------------------------------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------
# Security Group
# ---------------------------------------------------------

resource "aws_security_group" "ec2" {
  name        = "jenkins-docker-lab-sg"
  description = "Security group for Jenkins Docker lab EC2"
  vpc_id      = aws_vpc.lab.id

  # HTTP - Nginx
  ingress {
    description = "HTTP - Nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  # Jenkins
  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  # Outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "jenkins-docker-lab-sg"
  }
}

# ---------------------------------------------------------
# ECR Repository
# ---------------------------------------------------------

resource "aws_ecr_repository" "nginx" {
  name = "jenkins-docker-lab/nginx"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "jenkins-docker-lab-nginx"
  }
}

# ---------------------------------------------------------
# IAM Role for EC2
# ---------------------------------------------------------

resource "aws_iam_role" "ec2" {
  name = "jenkins-docker-lab-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "jenkins-docker-lab-ec2-role"
  }
}

# ---------------------------------------------------------
# Allow EC2 to pull images from ECR
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role = aws_iam_role.ec2.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ---------------------------------------------------------
# Instance Profile
# ---------------------------------------------------------

resource "aws_iam_instance_profile" "jenkins" {
  name = "jenkins-docker-lab-ec2-profile"

  role = aws_iam_role.ec2.name
}

# ---------------------------------------------------------
# Latest Amazon Linux 2023 AMI
# ---------------------------------------------------------

data "aws_ami" "amazon_linux" { 
  most_recent = true

  owners = [
    "amazon"
  ]

  filter {
    name   = "name"
    values = [
      "al2023-ami-*-x86_64"
    ]
  }

  filter {
    name   = "architecture"
    values = [
      "x86_64"
    ]
  }

  filter {
    name   = "root-device-type"
    values = [
      "ebs"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = [
      "hvm"
    ]
  }
}

# ---------------------------------------------------------
# EC2
# ---------------------------------------------------------
resource "aws_instance" "jenkins" {
  ami = data.aws_ami.amazon_linux.id

  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
  aws_security_group.ec2.id
  ]

  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  associate_public_ip_address = true

  user_data = file(
    "${path.module}/scripts/jenkins-user-data.sh"
  )

  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-jenkins"
  }
}
