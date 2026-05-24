

# Service Module Block
#
# Appended to main.tf for each subsequent service.
# Variables for this service are appended to variables.tf separately.

# ============================================
# Security Group: blink_test
# (per-service — independent ports from other services)
# ============================================

resource "aws_security_group" "blink_test" {
  name        = "blink-blink_test-sg"
  description = "Security group for service blink_test"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.blink_test_ingress_ports
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
    Name      = "blink-blink_test-sg"
    Service   = "blink_test"
    ManagedBy = "blink"
  }
}

# ============================================
# Service: blink_test
# ============================================

module "service_blink_test" {
  source = "./modules/ec2"

  service_name         = "blink_test"
  instance_type        = var.blink_test_instance_type
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = aws_security_group.blink_test.id
  iam_instance_profile = module.iam.instance_profile_name
  use_elastic_ip       = var.blink_test_use_elastic_ip
}


output "service_blink_test_ip" {
  description = "Service public IP"
  value       = module.service_blink_test.public_ip
}

output "service_blink_test_instance_id" {
  description = "Service EC2 instance ID (for SSM)"
  value       = module.service_blink_test.instance_id
}

output "service_blink_test_url" {
  description = "Service URL"
  value       = "http://${module.service_blink_test.public_ip}:3000"
}
