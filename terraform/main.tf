provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

terraform {
  backend "s3" {
    bucket         = "danzo-tfstate-bucket"
    key            = "terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
  }
  required_providers {
    aws ={
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "gitlab-runner-vpc"
  }
}

# Private Subnets for GitLab Runners
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "gitlab-runner-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "gitlab-runner-private-2"
  }
}

# Public Subnet (for NAT Gateway)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "gitlab-runner-public-1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "gitlab-runner-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "gitlab-runner-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "gitlab-runner-public-rt"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "gitlab-runner-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# Security Group for GitLab Runner
resource "aws_security_group" "gitlab_runner" {
  name        = "gitlab-runner-sg"
  description = "Security group for GitLab runner"
  vpc_id      = aws_vpc.main.id

  # No inbound rules by default - runners in private subnet
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gitlab-runner-sg"
  }
}

# Add this data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create IAM role for EC2 with Session Manager access
resource "aws_iam_role" "gitlab_runner" {
  name = "gitlab-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach SSM policy to the role
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.gitlab_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create instance profile
resource "aws_iam_instance_profile" "gitlab_runner" {
  name = "gitlab-runner-profile"
  role = aws_iam_role.gitlab_runner.name
}

# EC2 Instance for GitLab Runner
resource "aws_instance" "gitlab_runner" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_1.id  # Place in private subnet

  # Add the IAM instance profile
  iam_instance_profile = aws_iam_instance_profile.gitlab_runner.name

  vpc_security_group_ids = [aws_security_group.gitlab_runner.id]

  tags = {
    Name = "GitLab-Runner"
  }

  user_data = <<-EOF
              #!/bin/bash
              
              # Install SSM agent (already included in Amazon Linux 2023, but ensure it's running)
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              
              # Update system
              dnf update -y
              dnf install -y curl

              # Install GitLab Runner
              curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
              sudo dnf install -y gitlab-runner              

              # Register the runner (you'll need to do this manually or use SSM to provide the token)
              sudo gitlab-runner register \
                --non-interactive \
                --url "https://gitlab.com/" \
                --token "glrt-t3_9iZbfRbRGwXDSAhybb8L" \
                --executor "shell" \
                --description "AWS EC2 Runner"
              
              # Verify the runner status
              gitlab-runner status
              EOF
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_1_id" {
  value = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  value = aws_subnet.private_2.id
}