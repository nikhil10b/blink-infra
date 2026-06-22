# Global Variables
# Created by Blink on first service deployment.
# Per-service variables are appended below as new services are onboarded.

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (production | staging | dev)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR block � shared across all services in this deployment"
  type        = string
  default     = "10.0.0.0/16"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

variable "base_domain" {
  description = "Base domain (e.g. acme.com)"
  type        = string
  default     = ""
}

# ============================================
# Per-Service Variables: test_demo
# ============================================

variable "test_demo_instance_type" {
  description = "EC2 instance type for test_demo"
  type        = string
  default     = "t3.small"
}

variable "test_demo_ingress_ports" {
  description = "Ports to open for test_demo"
  type        = list(number)
  default     = [80,443,22]
}

variable "test_demo_use_elastic_ip" {
  description = "Use Elastic IP for test_demo"
  type        = bool
  default     = true
}

# ============================================
# RDS Variables: test_demo_db
# ============================================

variable "test_demo_db_db_engine" {
  description = "Database engine for test_demo_db"
  type        = string
  default     = "postgres"
}

variable "test_demo_db_db_engine_version" {
  description = "Database engine version for test_demo_db"
  type        = string
  default     = "15.4"
}

variable "test_demo_db_db_instance_class" {
  description = "RDS instance class for test_demo_db"
  type        = string
  default     = "db.t3.micro"
}

variable "test_demo_db_db_name" {
  description = "Database name for test_demo_db"
  type        = string
  default     = "test_demo"
}

variable "test_demo_db_db_username" {
  description = "Database master username for test_demo_db"
  type        = string
  default     = "blinkadmin"
}

variable "test_demo_db_db_multi_az" {
  description = "Enable Multi-AZ deployment for test_demo_db"
  type        = bool
  default     = false
}
