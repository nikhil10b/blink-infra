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
# Per-Service Variables: demo_api
# ============================================

variable "demo_api_instance_type" {
  description = "EC2 instance type for demo_api"
  type        = string
  default     = "t3.small"
}

variable "demo_api_ingress_ports" {
  description = "Ports to open for demo_api"
  type        = list(number)
  default     = [80,443,22]
}

variable "demo_api_use_elastic_ip" {
  description = "Use Elastic IP for demo_api"
  type        = bool
  default     = true
}
