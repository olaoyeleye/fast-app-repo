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

      yum update -y

      # Install AWS CLI v2
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install

      # Install kubectl
      curl -LO "https://dl.k8s.io/release/$$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      chmod +x kubectl
      mv kubectl /usr/local/bin/

      # Connect to EKS — allow this to fail without stopping the script
      aws eks update-kubeconfig \
        --name ${aws_eks_cluster.main.name} \
        --region ${var.region} || echo "WARNING: eks update-kubeconfig failed, run manually later"

      # Install nginx — this will now always run
      yum install -y nginx
      systemctl start nginx
      systemctl enable nginx

      echo "DONE"
  EOF
  
  tags = {
    Name = var.instance-name-nginx
  }
}