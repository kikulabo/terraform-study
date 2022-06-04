terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.17.0"
    }
  }
  required_version = "~> 1.2.0"
}

provider "aws" {
  profile = "default"
  region  = "ap-northeast-1"

  default_tags {
    tags = {
      created_by = "terraform"
    }
  }
}

locals {
  env = "test"
}

# VPCの作成
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.env}-vpc"
  }
}

# パブリックサブネットの作成
resource "aws_subnet" "test_subnet" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${local.env}-pub-sub-a"
  }
}

# IGW の作成
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "${local.env}-igw"
  }
}

# ルートテーブルの作成
resource "aws_route_table" "test_rtb" {
  vpc_id = aws_vpc.test_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name = "${local.env}-pub-sub-rtb"
  }
}

# 作成したルートテーブルをサブネットに関連付け
resource "aws_route_table_association" "test_rtb_association" {
  subnet_id      = aws_subnet.test_subnet.id
  route_table_id = aws_route_table.test_rtb.id
}

# セキュリティグループの作成
resource "aws_security_group" "test_sg" {
  name   = "test-sg"
  vpc_id = aws_vpc.test_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.env}-sg"
  }
}

resource "aws_instance" "test_ec2" {
  ami                         = "ami-02c3627b04781eada"
  instance_type               = "t2.micro"

  associate_public_ip_address = true

  subnet_id              = aws_subnet.test_subnet.id
  vpc_security_group_ids = [aws_security_group.test_sg.id]

  user_data = <<EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    
    chown -R apache:apache /var/www/html
    echo "Hello Terraform" | sudo tee /var/www/html/index.html

    systemctl start httpd
    systemctl enable httpd
    EOF

  tags = {
    Name = "${local.env}-ec2"
  }
}

output "ec2_dns" {
  value = aws_instance.test_ec2.public_dns
}