name: Deploy Entire Infra

on:
  push:
    branches: [ feat-dev ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_wrapper: false

    - name: Create terraform.tfvars
      working-directory: ./terraform
      run: |
        cat > terraform.tfvars <<EOF
        region              = "${{ secrets.AWS_REGION }}"
        ami                 = "${{ secrets.AMI_ID }}"
        instance_type       = "${{ secrets.INSTANCE_TYPE }}"
        instance-name-nginx = "${{ secrets.INSTANCE_NAME_NGINX }}"
        vpc_name            = "${{ secrets.VPC_NAME }}"
        key_name            = "${{ secrets.KEY_NAME }}"
        EOF

    - name: Terraform Init
      working-directory: ./terraform
      run: terraform init

    - name: Terraform Plan
      working-directory: ./terraform
      run: terraform plan -out=tfplan

    - name: Terraform Apply
      working-directory: ./terraform
      run: terraform apply -auto-approve tfplan

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2

    - name: Build, Tag and Push image to ECR
      id: build-image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: fast-app-repo
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
        echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

    - name: Install Ansible
      run: |
        python3 -m pip install --upgrade pip
        python3 -m pip install ansible boto3 botocore

    - name: Install eksctl
      run: |
        curl --silent --location \
          "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" \
          | tar xz -C /tmp
        sudo mv /tmp/eksctl /usr/local/bin

    - name: Install kubectl
      run: |
        curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/

    - name: Get Nginx public IP
      id: nginx-ip
      working-directory: ./terraform
      run: echo "NGINX_IP=$(terraform output -raw nginx_public_ip)" >> $GITHUB_OUTPUT

    - name: Save SSH private key
      run: |
        mkdir -p ~/.ssh
        echo "${{ secrets.ANSIBLE_SSH_PRIVATE_KEY }}" > ~/.ssh/ansible_key.pem
        chmod 600 ~/.ssh/ansible_key.pem

    - name: Add EC2 IAM role to EKS aws-auth
      run: |
        aws eks update-kubeconfig \
          --name ${{ secrets.EKS_CLUSTER_NAME }} \
          --region ${{ secrets.AWS_REGION }}

        eksctl create iamidentitymapping \
          --cluster ${{ secrets.EKS_CLUSTER_NAME }} \
          --region ${{ secrets.AWS_REGION }} \
          --arn arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/${{ secrets.VPC_NAME }}-ec2-eks-role \
          --username ec2-eks-role \
          --group system:masters \
          --no-duplicate-arns

    - name: Create Ansible inventory
      run: |
        cat > ansible/hosts.ini <<EOF
        [nginx]
        nginx ansible_host=${{ steps.nginx-ip.outputs.NGINX_IP }}

        [nginx:vars]
        ansible_user=ec2-user
        ansible_ssh_private_key_file=~/.ssh/ansible_key.pem
        aws_region=${{ secrets.AWS_REGION }}
        eks_cluster_name=${{ secrets.EKS_CLUSTER_NAME }}
        EOF

    - name: Run Ansible playbook
      run: |
        ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yml \
          --extra-vars "app_image=${{ steps.login-ecr.outputs.registry }}/fast-app-repo:${{ github.sha }}"

    - name: Get Load Balancer URL
      run: |
        kubectl get service fast-app-service \
          -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'