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
# Per-Service Variables: c
# ============================================

variable "c_instance_type" {
  description = "EC2 instance type for c"
  type        = string
  default     = "t3.small"
}

variable "c_ingress_ports" {
  description = "Ports to open for c"
  type        = list(number)
  default     = [80,443,22]
}

variable "c_use_elastic_ip" {
  description = "Use Elastic IP for c"
  type        = bool
  default     = true
}

# ============================================
# RDS Variables: c_db
# ============================================

variable "c_db_db_engine" {
  description = "Database engine for c_db"
  type        = string
  default     = "postgres"
}

variable "c_db_db_engine_version" {
  description = "Database engine version for c_db"
  type        = string
  default     = "15.4"
}

variable "c_db_db_instance_class" {
  description = "RDS instance class for c_db"
  type        = string
  default     = "db.t3.micro"
}

variable "c_db_db_name" {
  description = "Database name for c_db"
  type        = string
  default     = "c"
}

variable "c_db_db_username" {
  description = "Database master username for c_db"
  type        = string
  default     = "blinkadmin"
}

variable "c_db_db_multi_az" {
  description = "Enable Multi-AZ deployment for c_db"
  type        = bool
  default     = false
}
