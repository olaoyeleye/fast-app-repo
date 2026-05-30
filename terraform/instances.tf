resource "aws_instance" "nginx" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public-kunle-subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Attach the IAM role
  iam_instance_profile   = aws_iam_instance_profile.ec2_eks_profile.name

  user_data = <<-EOF
    #!/bin/bash
    set -e
    # Update system
    yum update -y

    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # Configure kubeconfig for EKS
    aws eks update-kubeconfig \
      --name ${aws_eks_cluster.main.name} \
      --region ${var.aws_region}

    # Install nginx
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = {
    Name = var.instance_name_nginx
  }
}