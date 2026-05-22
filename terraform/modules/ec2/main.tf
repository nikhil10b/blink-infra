# EC2 Module - Terraform Template
#
# Creates:
# - EC2 instance with Docker pre-installed
# - Optional Elastic IP
# - IAM instance profile for SSM

variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID"
  type        = string
}

variable "use_elastic_ip" {
  description = "Use Elastic IP for static address"
  type        = bool
  default     = false
}

variable "iam_instance_profile" {
  description = "IAM instance profile name (for SSM)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "SSH key pair name (optional, use SSM instead)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "service" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  
  # IAM profile for SSM access
  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : null
  
  # SSH key (optional)
  key_name = var.key_name != "" ? var.key_name : null

  # User data script to install Docker
  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name      = "blink-${var.service_name}"
    Service   = var.service_name
    ManagedBy = "blink"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP (optional)
resource "aws_eip" "service" {
  count    = var.use_elastic_ip ? 1 : 0
  instance = aws_instance.service.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name      = "blink-${var.service_name}-eip"
    Service   = var.service_name
    ManagedBy = "blink"
  })
}

# Outputs
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.service.id
}

output "public_ip" {
  description = "Public IP address (Elastic IP if enabled, otherwise instance IP)"
  value       = var.use_elastic_ip ? aws_eip.service[0].public_ip : aws_instance.service.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.service.private_ip
}

output "public_dns" {
  description = "Public DNS name"
  value       = aws_instance.service.public_dns
}
