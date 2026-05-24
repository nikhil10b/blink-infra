

# ============================================
# Per-Service Variables: test_demo_app
# ============================================

variable "test_demo_app_instance_type" {
  description = "EC2 instance type for test_demo_app"
  type        = string
  default     = "t3.small"
}

variable "test_demo_app_ingress_ports" {
  description = "Ports to open for test_demo_app"
  type        = list(number)
  default     = [80,443,22]
}

variable "test_demo_app_use_elastic_ip" {
  description = "Use Elastic IP for test_demo_app"
  type        = bool
  default     = true
}
