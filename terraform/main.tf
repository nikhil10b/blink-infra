# Root Terraform - First Service
#
# Contains: provider, base infrastructure modules, first service EC2, outputs.
# Variables live in variables.tf (created alongside this file).

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend will be configured dynamically
  # backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "blink"
      Environment = var.environment
    }
  }
}

# ============================================
# Base Infrastructure (created ONCE)
# ============================================

module "iam" {
  source = "./modules/iam"
  name   = "blink"
}

module "vpc" {
  source        = "./modules/vpc"
  name          = "blink"
  cidr          = var.vpc_cidr
  ingress_ports = var.c_ingress_ports
}

# ============================================
# Security Group: c
# ============================================

resource "aws_security_group" "c" {
  name        = "blink-c-sg"
  description = "Security group for service c"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.c_ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Port ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name      = "blink-c-sg"
    Service   = "c"
    ManagedBy = "blink"
  }
}

# ============================================
# Service: c
# ============================================

module "service_c" {
  source = "./modules/ec2"

  service_name         = "c"
  instance_type        = var.c_instance_type
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = aws_security_group.c.id
  iam_instance_profile = module.iam.instance_profile_name
  use_elastic_ip       = var.c_use_elastic_ip
}


# ============================================
# Outputs
# ============================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "service_c_ip" {
  description = "Service public IP"
  value       = module.service_c.public_ip
}

output "service_c_instance_id" {
  description = "Service EC2 instance ID (for SSM)"
  value       = module.service_c.instance_id
}

output "service_c_url" {
  description = "Service URL"
  value       = "http://${module.service_c.public_ip}:3000"
}

# ============================================
# Database: c_db
# Engine: postgres — managed by Blink
# ============================================

module "db_c_db" {
  source = "./modules/rds"

  name                  = "c_db"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  app_security_group_id = aws_security_group.c.id
  engine                = var.c_db_db_engine
  engine_version        = var.c_db_db_engine_version
  instance_class        = var.c_db_db_instance_class
  db_name               = var.c_db_db_name
  db_username           = var.c_db_db_username
  multi_az              = var.c_db_db_multi_az
}

output "db_c_db_endpoint" {
  description = "RDS endpoint (host:port) for c_db"
  value       = module.db_c_db.endpoint
}

output "db_c_db_address" {
  description = "RDS hostname for c_db"
  value       = module.db_c_db.address
}

output "db_c_db_port" {
  description = "RDS port for c_db"
  value       = module.db_c_db.port
}

output "db_c_db_password_ssm" {
  description = "SSM Parameter Store path containing DB password for c_db"
  value       = module.db_c_db.db_password_ssm_path
}
