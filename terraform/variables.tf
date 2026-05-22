# Global Variables
# Created by Blink on first service deployment.
# Per-service variables are appended below as new services are onboarded.

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
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
# Per-Service Variables: test_app
# ============================================

variable "test_app_instance_type" {
  description = "EC2 instance type for test_app"
  type        = string
  default     = "t3.small"
}

variable "test_app_ingress_ports" {
  description = "Ports to open for test_app"
  type        = list(number)
  default     = [80,443,3000]
}

variable "test_app_use_elastic_ip" {
  description = "Use Elastic IP for test_app"
  type        = bool
  default     = true
}
