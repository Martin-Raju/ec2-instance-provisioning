provider "aws" {
  region = var.aws_region
}

# Default VPC & Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group
module "security_group" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 5.0"
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "SSH"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

# --- Launch Template (Spot Instances) ---
resource "aws_launch_template" "spot_lt" {
  name_prefix            = "spot-lt"
  image_id               = var.ami_id
  instance_type          = var.default_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [module.security_group.security_group_id]

  instance_market_options {
    market_type = "spot"
  }

  network_interfaces {
    associate_public_ip_address = true
  }
}

