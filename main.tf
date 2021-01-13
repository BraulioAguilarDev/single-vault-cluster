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

resource "aws_vpc" "vpc_dev" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_dev"
  }
}

resource "aws_internet_gateway" "internet_gateway_dev" {
  vpc_id = aws_vpc.vpc_dev.id

  tags = {
    Name = "ig_dev"
  }
}

resource "aws_subnet" "subnet_dev" {
  vpc_id     = aws_vpc.vpc_dev.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "us-west-2a"

  tags = {
    Name = "subnet_dev"
  }
}

// Dirige todo el tráfico (0.0.0.0/0) a la puerta de enlace de Internet 
// y asociar esta tabla de rutas con ambas subredes. 
// Cada subred de la VPC debe estar asociada a una tabla de rutas.
resource "aws_route_table" "public_dev" {
  vpc_id = aws_vpc.vpc_dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_dev.id
  }
}

resource "aws_route_table_association" "route_table_association_dev" {
  subnet_id      = aws_subnet.subnet_dev.id
  route_table_id = aws_route_table.public_dev.id
}


data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_dev" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}


resource "aws_security_group" "security_group_dev" {
  name        = "security_group_dev"
  description = "Rules ssh/web security group"
  vpc_id      = aws_vpc.vpc_dev.id

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

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security_group_dev"
  }
}

module "consul_cluster" {

  source = "./modules/consul"

  ami_id               = var.consult_ami_id
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_group_id    = aws_security_group.security_group_dev.id
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config"

  vpc_zone_identifier = [aws_subnet.subnet_dev.id]

  cluster_name = var.consul_cluster_name

  cluster_min_size = var.consul_cluster_min_size
  cluster_max_size = var.consul_cluster_max_size
  instance_type    = var.consul_instance_type
  desired_capacity = var.consul_desired_capacity
}

module "vault_cluster" {
  source = "./modules/vault"

  ami_id               = var.vault_ami_id
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_group_id    = aws_security_group.security_group_dev.id
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config"

  vpc_zone_identifier = [aws_subnet.subnet_dev.id]

  cluster_name = var.vault_cluster_name

  cluster_min_size = var.vault_cluster_min_size
  cluster_max_size = var.vault_cluster_max_size
  instance_type    = var.vault_instance_type
  desired_capacity = var.vault_desired_capacity
}
