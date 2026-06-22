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

  # Backend configured dynamically via -backend-config at init time.
  # Keep this block empty (partial config); values are injected by the agent.
  backend "s3" {}
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
  ingress_ports = var.test_demo_ingress_ports
}

# ============================================
# Security Group: test_demo
# ============================================

resource "aws_security_group" "test_demo" {
  name        = "blink-test_demo-sg"
  description = "Security group for service test_demo"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.test_demo_ingress_ports
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
    Name      = "blink-test_demo-sg"
    Service   = "test_demo"
    ManagedBy = "blink"
  }
}

# ============================================
# Service: test_demo
# ============================================

module "service_test_demo" {
  source = "./modules/ec2"

  service_name         = "test_demo"
  instance_type        = var.test_demo_instance_type
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = aws_security_group.test_demo.id
  iam_instance_profile = module.iam.instance_profile_name
  use_elastic_ip       = var.test_demo_use_elastic_ip
}


# ============================================
# Outputs
# ============================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "service_test_demo_ip" {
  description = "Service public IP"
  value       = module.service_test_demo.public_ip
}

output "service_test_demo_instance_id" {
  description = "Service EC2 instance ID (for SSM)"
  value       = module.service_test_demo.instance_id
}

output "service_test_demo_url" {
  description = "Service URL"
  value       = "http://${module.service_test_demo.public_ip}:3000"
}

# ============================================
# Database: test_demo_db
# Engine: postgres — managed by Blink
# ============================================

module "db_test_demo_db" {
  source = "./modules/rds"

  name                  = "test_demo_db"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  app_security_group_id = aws_security_group.test_demo.id
  engine                = var.test_demo_db_db_engine
  engine_version        = var.test_demo_db_db_engine_version
  instance_class        = var.test_demo_db_db_instance_class
  db_name               = var.test_demo_db_db_name
  db_username           = var.test_demo_db_db_username
  multi_az              = var.test_demo_db_db_multi_az
}

output "db_test_demo_db_endpoint" {
  description = "RDS endpoint (host:port) for test_demo_db"
  value       = module.db_test_demo_db.endpoint
}

output "db_test_demo_db_address" {
  description = "RDS hostname for test_demo_db"
  value       = module.db_test_demo_db.address
}

output "db_test_demo_db_port" {
  description = "RDS port for test_demo_db"
  value       = module.db_test_demo_db.port
}

output "db_test_demo_db_password_ssm" {
  description = "SSM Parameter Store path containing DB password for test_demo_db"
  value       = module.db_test_demo_db.db_password_ssm_path
}
