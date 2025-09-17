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
}

# --- Auto Scaling Group using the module ---
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 8.0"

  name                = "spot-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity

  # --- Use existing launch template ---
  launch_template_id      = aws_launch_template.spot_lt.id
  launch_template_version = "$Latest"

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tags = {
    Name        = "spot-asg-instance"
    Environment = var.environment
  }
  create_launch_template = false

  scaling_policies = [
    {
      name                      = "cpu-target-tracking"
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = var.cpu_target_value
      }
    }
  ]
}
