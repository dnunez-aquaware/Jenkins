resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "gitops-lab-vpc"
    Environment = "lab"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "gitops-lab-igw"
    Environment = "lab"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "gitops-lab-public-a"
    Environment = "lab"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.102.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "gitops-lab-public-b"
    Environment = "lab"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "gitops-lab-private-a"
    Environment = "lab"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "gitops-lab-private-b"
    Environment = "lab"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "gitops-lab-nat-eip"
    Environment = "lab"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name        = "gitops-lab-nat"
    Environment = "lab"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "gitops-lab-public-rt"
    Environment = "lab"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "gitops-lab-private-rt"
    Environment = "lab"
  }
}


resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
#----------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks_cluster" {
  name = "gitops-lab-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "eks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_nodes" {
  name = "gitops-lab-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"//permite que pueda interactuar con servicios AWS para funcionar
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_nodes.name //propoprcionar networking a nodos
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr" {
  role       = aws_iam_role.eks_nodes.name //permite descargar imagenes del ECR
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_eks_cluster" "main" {
  name     = "gitops-lab"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.34"

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    endpoint_public_access  = true
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster
  ]

  tags = {
    Environment = "lab"
  }
}

resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# resource "aws_security_group" "nodes" {
#   name        = "gitops-lab-node-sg"
#   description = "Security group for EKS worker nodes"
#   vpc_id      = aws_vpc.main.id

#   tags = {
#     Name        = "gitops-lab-node-sg"
#     Environment = "lab"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "nodes_internal" {
#   security_group_id = aws_security_group.nodes.id

#   ip_protocol = "-1"
#   cidr_ipv4   = "10.0.0.0/16"
# }

# resource "aws_vpc_security_group_egress_rule" "nodes_all" {
#   security_group_id = aws_security_group.nodes.id

#   ip_protocol = "-1"
#   cidr_ipv4   = "0.0.0.0/0"
# }

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main"

  node_role_arn = aws_iam_role.eks_nodes.arn

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  instance_types = ["t3.medium"]

  scaling_config {
    min_size     = 1
    desired_size = 1
    max_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr
  ]

  tags = {
    Environment = "lab"
  }
}