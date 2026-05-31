# instances.tf

resource "aws_iam_role" "ec2_eks_role" {
  name = "${var.vpc_name}-ec2-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_eks_policy" {
  role       = aws_iam_role.ec2_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy" "ec2_eks_inline" {
  name = "ec2-eks-inline"
  role = aws_iam_role.ec2_eks_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:AccessKubernetesApi"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_eks_profile" {
  name = "${var.vpc_name}-ec2-eks-profile"
  role = aws_iam_role.ec2_eks_role.name
}

resource "aws_instance" "nginx" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public-kunle-subnet.id
  vpc_security_group_ids = [aws_security_group.public-kunle-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_eks_profile.name
  user_data = <<-EOF
      #!/bin/bash
      exec > /var/log/user-data.log 2>&1
      set -e

      if command -v yum >/dev/null 2>&1; then
        yum update -y
        yum install -y nginx
      elif command -v dnf >/dev/null 2>&1; then
        dnf update -y
        dnf install -y nginx
      elif command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y nginx
      else
        echo "ERROR: unsupported package manager" >&2
        exit 1
      fi

      systemctl enable nginx
      systemctl start nginx
      echo "nginx installed and started"
  EOF
  
  tags = {
    Name = var.instance-name-nginx
  }
}