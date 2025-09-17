provider "aws" {
  region = var.aws_region
}

# Get default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Use AWS EC2 module
module "spot_instance" {
  for_each = toset(var.instance_types)
  source   = "terraform-aws-modules/ec2-instance/aws"
  version  = "~> 4.0"

  name = "Ec2-Spot-${each.key}"

  ami           = var.ami_id
  instance_type = each.value
  key_name      = var.key_name

  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.security_group.security_group_id]

  # Spot settings
  create_spot_instance = true
  spot_price           = var.max_spot_price
  wait_for_fulfillment = true
  tags = {
    Environment  = var.environment
    Terraform    = "true"
    InstanceType = each.value
  }
}

# Security Group module
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

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

