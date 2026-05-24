

# Service Module Block
#
# Appended to main.tf for each subsequent service.
# Variables for this service are appended to variables.tf separately.

# ============================================
# Security Group: test_demo_app
# (per-service — independent ports from other services)
# ============================================

resource "aws_security_group" "test_demo_app" {
  name        = "blink-test_demo_app-sg"
  description = "Security group for service test_demo_app"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.test_demo_app_ingress_ports
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
    Name      = "blink-test_demo_app-sg"
    Service   = "test_demo_app"
    ManagedBy = "blink"
  }
}

# ============================================
# Service: test_demo_app
# ============================================

module "service_test_demo_app" {
  source = "./modules/ec2"

  service_name         = "test_demo_app"
  instance_type        = var.test_demo_app_instance_type
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = aws_security_group.test_demo_app.id
  iam_instance_profile = module.iam.instance_profile_name
  use_elastic_ip       = var.test_demo_app_use_elastic_ip
}


output "service_test_demo_app_ip" {
  description = "Service public IP"
  value       = module.service_test_demo_app.public_ip
}

output "service_test_demo_app_instance_id" {
  description = "Service EC2 instance ID (for SSM)"
  value       = module.service_test_demo_app.instance_id
}

output "service_test_demo_app_url" {
  description = "Service URL"
  value       = "http://${module.service_test_demo_app.public_ip}:3000"
}
