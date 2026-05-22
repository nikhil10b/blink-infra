# VPC Module - Terraform Template
#
# Creates:
# - VPC with configurable CIDR
# - Public subnet
# - Internet Gateway
# - Route table
# - Security Group with configurable ingress

variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "blink"
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ingress_ports" {
  description = "Ports to open for ingress"
  type        = list(number)
  default     = [22, 80, 443]
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name      = "${var.name}-vpc"
    ManagedBy = "blink"
  })
}

# Public Subnet A (primary — used by EC2)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = merge(var.tags, {
    Name      = "${var.name}-public-subnet-a"
    ManagedBy = "blink"
  })
}

# Public Subnet B (second AZ — required for RDS DB subnet group)
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr, 8, 2)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = merge(var.tags, {
    Name      = "${var.name}-public-subnet-b"
    ManagedBy = "blink"
  })
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name      = "${var.name}-igw"
    ManagedBy = "blink"
  })
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name      = "${var.name}-public-rt"
    ManagedBy = "blink"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "default" {
  name        = "${var.name}-default-sg"
  description = "Default security group managed by Blink"
  vpc_id      = aws_vpc.main.id

  # Dynamic ingress rules based on ingress_ports
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ingress.value == 22 ? var.ssh_allowed_cidrs : ["0.0.0.0/0"]
      description = "Port ${ingress.value}"
    }
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name      = "${var.name}-default-sg"
    ManagedBy = "blink"
  })
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Primary public subnet ID (used by EC2)"
  value       = aws_subnet.public.id
}

output "public_subnet_ids" {
  description = "All public subnet IDs across both AZs (used by RDS DB subnet group)"
  value       = [aws_subnet.public.id, aws_subnet.public_b.id]
}

output "security_group_id" {
  description = "Default security group ID"
  value       = aws_security_group.default.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}
