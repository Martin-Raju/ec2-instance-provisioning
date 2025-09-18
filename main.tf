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

# --- Auto Scaling Group with Launch Template and Mixed Instances ---
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name                = "spot-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tags = {
    Name        = "spot-asg-instance"
    Environment = var.environment
  }

  # --- Launch Template parameters ---
  create_launch_template = true
  force_delete           = true
  launch_template_name   = "spot-lt"
  image_id               = var.ami_id
  key_name               = var.key_name
  instance_type          = "t2.micro"
  user_data = base64encode(<<-EOT
    #!/bin/bash
    yum install -y stress
    stress --cpu 3 --timeout 600 &
  EOT
  )
  # Mixed Instances Policy
  mixed_instances_policy = {
    launch_template = {
      version = "Latest"
    }
    instances_distribution = {
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
      spot_allocation_strategy                 = "lowest-price"
    }
  }
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
