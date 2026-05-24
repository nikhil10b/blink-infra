

# ============================================
# Per-Service Variables: test_deploy
# ============================================

variable "test_deploy_instance_type" {
  description = "EC2 instance type for test_deploy"
  type        = string
  default     = "t3.small"
}

variable "test_deploy_ingress_ports" {
  description = "Ports to open for test_deploy"
  type        = list(number)
  default     = [80,443,22]
}

variable "test_deploy_use_elastic_ip" {
  description = "Use Elastic IP for test_deploy"
  type        = bool
  default     = true
}
