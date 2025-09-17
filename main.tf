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
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name                = "mixed-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4

  # Launch template arguments
  launch_template = {
    name_prefix                 = "asg-lt"
    image_id                    = var.ami_id
    instance_type               = var.instance_type
    key_name                    = var.key_name
    security_groups             = [module.security_group.security_group_id]
    associate_public_ip_address = true
  }
}