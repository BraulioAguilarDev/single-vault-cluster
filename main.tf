terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.22.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc_vault" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "VPC Vault"
    Environment = "testing"
  }
}

resource "aws_subnet" "subnet_vault" {
  vpc_id            = aws_vpc.vpc_vault.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name        = "Public Subnet Vault"
    Environment = "testing"
  }
}

resource "aws_internet_gateway" "internet_gateway_vault" {
  vpc_id = aws_vpc.vpc_vault.id

  tags = {
    Name        = "Internet Gateway Vault"
    Environment = "testing"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc_vault.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_vault.id
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet_vault.id
  route_table_id = aws_route_table.route_table.id
}


data "aws_iam_policy_document" "policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "role-vault"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "default" {
  name = "profile-vault"
  role = aws_iam_role.role.name
}

resource "aws_security_group" "security_group_vault" {
  name        = "security_group_vault"
  description = "Rules ssh/web security group"
  vpc_id      = aws_vpc.vpc_vault.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Security Group Vault"
    Environment = "testing"
  }
}

module "consul_cluster" {

  source = "./modules/consul"

  ami_id               = var.consult_ami_id
  iam_instance_profile = aws_iam_instance_profile.default.name
  security_group_id    = aws_security_group.security_group_vault.id
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config"

  vpc_zone_identifier = [aws_subnet.subnet_vault.id]

  cluster_name = var.consul_cluster_name

  cluster_min_size = var.consul_cluster_min_size
  cluster_max_size = var.consul_cluster_max_size
  instance_type    = var.consul_instance_type
  desired_capacity = var.consul_desired_capacity
}

module "vault_cluster" {
  source = "./modules/vault"

  ami_id               = var.vault_ami_id
  iam_instance_profile = aws_iam_instance_profile.default.name
  security_group_id    = aws_security_group.security_group_vault.id
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config"

  vpc_zone_identifier = [aws_subnet.subnet_vault.id]

  cluster_name = var.vault_cluster_name

  cluster_min_size = var.vault_cluster_min_size
  cluster_max_size = var.vault_cluster_max_size
  instance_type    = var.vault_instance_type
  desired_capacity = var.vault_desired_capacity
}
