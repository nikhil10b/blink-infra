# IAM Module - Terraform Template
#
# Creates:
# - IAM role for EC2 instances (SSM access)
# - Instance profile

variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "blink"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# IAM Role for EC2 (SSM access)
resource "aws_iam_role" "ec2_ssm" {
  name = "${var.name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.name}-ec2-ssm-role"
    ManagedBy = "blink"
  })
}

# Attach SSM managed policy
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach ECR read-only policy (for pulling images)
resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Inline policy: read Blink SSM parameters (DB credentials, endpoints, etc.)
# AmazonSSMManagedInstanceCore covers SSM Session Manager but NOT GetParameter.
resource "aws_iam_role_policy" "blink_ssm_read" {
  name = "${var.name}-blink-ssm-read"
  role = aws_iam_role.ec2_ssm.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BlinkSSMParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/blink/*"
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name

  tags = merge(var.tags, {
    Name      = "${var.name}-ec2-ssm-profile"
    ManagedBy = "blink"
  })
}

# Outputs
output "instance_profile_name" {
  description = "Instance profile name for EC2 instances"
  value       = aws_iam_instance_profile.ec2_ssm.name
}

output "instance_profile_arn" {
  description = "Instance profile ARN"
  value       = aws_iam_instance_profile.ec2_ssm.arn
}

output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.ec2_ssm.name
}

output "role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.ec2_ssm.arn
}
