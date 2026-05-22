# RDS Module - Managed Database Instance
# Creates: RDS instance, DB subnet group, per-module security group.
# Password is auto-generated and stored in SSM Parameter Store.
# Subnet IDs must span at least 2 AZs (AWS DB subnet group requirement).

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

variable "name" {
  description = "Module name used for resource naming (e.g. myapp_db)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Two or more subnet IDs in different AZs for the DB subnet group"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group of the application — only this SG gets DB access"
  type        = string
}

variable "engine" {
  description = "Database engine: postgres or mysql"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version (e.g. 15.4 for postgres, 8.0.35 for mysql)"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "Master database username"
  type        = string
  default     = "blinkadmin"
}

variable "multi_az" {
  description = "Enable Multi-AZ standby replica"
  type        = bool
  default     = false
}

locals {
  db_port = var.engine == "postgres" ? 5432 : 3306
}

resource "random_password" "db" {
  length  = 20
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/blink/${var.name}/db_password"
  type  = "SecureString"
  value = random_password.db.result
  tags  = { ManagedBy = "blink"; Service = var.name }
}

resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/blink/${var.name}/db_endpoint"
  type  = "String"
  value = aws_db_instance.this.address
  tags  = { ManagedBy = "blink"; Service = var.name }
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/blink/${var.name}/db_port"
  type  = "String"
  value = tostring(aws_db_instance.this.port)
  tags  = { ManagedBy = "blink"; Service = var.name }
}

resource "aws_db_subnet_group" "this" {
  name       = "blink-${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name      = "blink-${var.name}-subnet-group"
    ManagedBy = "blink"
  }
}

resource "aws_security_group" "this" {
  name        = "blink-${var.name}-rds-sg"
  description = "RDS security group for ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = local.db_port
    to_port         = local.db_port
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
    description     = "DB access from app security group only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "blink-${var.name}-rds-sg"
    ManagedBy = "blink"
  }
}

resource "aws_db_instance" "this" {
  identifier        = "blink-${var.name}"
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = 20
  max_allocated_storage = 100

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  publicly_accessible    = false
  multi_az               = var.multi_az

  skip_final_snapshot       = false
  final_snapshot_identifier = "blink-${var.name}-final"
  deletion_protection       = false
  storage_encrypted         = true
  backup_retention_period   = 7

  tags = {
    Name      = "blink-${var.name}"
    ManagedBy = "blink"
    Service   = var.name
  }

  depends_on = [aws_db_subnet_group.this]
}

output "endpoint" {
  description = "RDS endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS hostname only"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "db_password_ssm_path" {
  description = "SSM Parameter Store path containing the database password"
  value       = aws_ssm_parameter.db_password.name
}

output "security_group_id" {
  description = "RDS security group ID (used by subsequent services to add ingress rules)"
  value       = aws_security_group.this.id
}
