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

resource "aws_launch_template" "asg_lt" {
  name_prefix            = "asg-lt"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [module.security_group.this_security_group_id]
  network_interfaces {
    associate_public_ip_address = true
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name                = "mixed-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4

  mixed_instances_policy = {
    launch_template = {
      launch_template_specification = {
        launch_template_id = aws_launch_template.asg_lt.id
        version            = "$Latest"
      }
    }
    instances_distribution = {
      on_demand_percentage_above_base_capacity = 50
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tags = [
    {
      key                 = "Environment"
      value               = var.environment
      propagate_at_launch = true
    }
  ]
}
