// VPC
resource "aws_vpc" "tfvpc1" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tfvpc1"
  }
}

// TWO PUBLIC SUBNETS
resource "aws_subnet" "tfsubnet1" {
  vpc_id                  = aws_vpc.tfvpc1.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tfsubnet1"
  }
}

resource "aws_subnet" "tfsubnet2" {
  vpc_id                  = aws_vpc.tfvpc1.id
  cidr_block              = "192.168.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "tfsubnet2"
  }
}

// IGW
resource "aws_internet_gateway" "tfigw1" {
  vpc_id = aws_vpc.tfvpc1.id
  tags = {
    Name = "tfigw1"
  }
}

// ROUTE TABLE AND ASSOCIATIONS
resource "aws_route_table" "tfrt1" {
  vpc_id = aws_vpc.tfvpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tfigw1.id
  }
  tags = {
    Name = "tfrt1"
  }
}

resource "aws_route_table_association" "tfrta1" {
  subnet_id      = aws_subnet.tfsubnet1.id
  route_table_id = aws_route_table.tfrt1.id
}
resource "aws_route_table_association" "tfrta2" {
  subnet_id      = aws_subnet.tfsubnet2.id
  route_table_id = aws_route_table.tfrt1.id
}

// SECURITY GROUP
resource "aws_security_group" "tfsg1" {
  vpc_id      = aws_vpc.tfvpc1.id
  description = "allow ssh and http"
  name        = "tfsg1"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "allow ssh"
    cidr_blocks = ["192.168.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "allow http"
    cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    description = "all outbound"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


// EKS CLUSTER ROLE
resource "aws_iam_role" "tfeksclusterrole" {
  name = "tfeksclusterrole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "tfpolicyattach1" {
  role       = aws_iam_role.tfeksclusterrole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

// EKS NODE GROUP ROLE
resource "aws_iam_role" "tfeksnodegrouprole" {
  name = "tfeksnodegrouprole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "tfpolicyattach2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.tfeksnodegrouprole.name
}

resource "aws_iam_role_policy_attachment" "tfpolicyattach3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.tfeksnodegrouprole.name
}

resource "aws_iam_role_policy_attachment" "tfpolicyattach4" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.tfeksnodegrouprole.name
}

// EKS CLUSTER
resource "aws_eks_cluster" "tfekscluster" {
  name     = "tfekscluster"
  role_arn = aws_iam_role.tfeksclusterrole.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.tfsubnet1.id,
      aws_subnet.tfsubnet2.id
    ]
    endpoint_public_access = true
  }

  depends_on = [aws_iam_role_policy_attachment.tfpolicyattach1]
}

// EKS NODE GROUP
resource "aws_eks_node_group" "tfeksnodegroup" {
  cluster_name    = aws_eks_cluster.tfekscluster.name
  node_group_name = "tfeksnodegroup"
  node_role_arn   = aws_iam_role.tfeksnodegrouprole.arn
  instance_types  = ["t2.medium"]
  ami_type        = "AL2_x86_64"
  subnet_ids = [
    aws_subnet.tfsubnet1.id,
    aws_subnet.tfsubnet2.id
  ]

  scaling_config {
    max_size     = 3
    min_size     = 1
    desired_size = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.tfpolicyattach2,
    aws_iam_role_policy_attachment.tfpolicyattach3,
    aws_iam_role_policy_attachment.tfpolicyattach4,
    aws_eks_cluster.tfekscluster
  ]
}