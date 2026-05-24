

# ============================================
# Per-Service Variables: blink_test
# ============================================

variable "blink_test_instance_type" {
  description = "EC2 instance type for blink_test"
  type        = string
  default     = "t3.small"
}

variable "blink_test_ingress_ports" {
  description = "Ports to open for blink_test"
  type        = list(number)
  default     = [80,443,22]
}

variable "blink_test_use_elastic_ip" {
  description = "Use Elastic IP for blink_test"
  type        = bool
  default     = true
}
