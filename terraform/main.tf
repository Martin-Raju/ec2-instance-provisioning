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
  source      = "./modules/terraform-aws-security-group-5.3.0"
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
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP"
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
  source                     = "./modules/terraform-aws-autoscaling-8.3.1"
  name                       = "Test-server"
  vpc_zone_identifier        = data.aws_subnets.default.ids
  min_size                   = var.asg_min_size
  max_size                   = var.asg_max_size
  desired_capacity           = var.asg_desired_capacity
  health_check_type          = "EC2"
  health_check_grace_period  = 300
  create_launch_template     = true
  force_delete               = true
  launch_template_name       = "spot-lt"
  image_id                   = var.ami_id
  key_name                   = var.key_name
  security_groups            = [module.security_group.security_group_id]
  use_mixed_instances_policy = true

  mixed_instances_policy = {
    instances_distribution = {
      base_capacity                            = 1
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
      spot_allocation_strategy                 = "capacity-optimized"
      on_demand_allocation_strategy            = "prioritized"
      #spot_instance_pools                      = 5
      #spot_max_price                           = var.spot_max_price
    }

    override = [
      { instance_type = "t3.small", spot_max_price = "0.01" },
      { instance_type = "t3.medium", spot_max_price = "0.02" },
      { instance_type = "t3a.small", spot_max_price = "0.01" },
      { instance_type = "t3a.medium", spot_max_price = "0.02" }
    ]
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
  tags = {
    Name        = "Asg-instance"
    Environment = var.environment
  }
}
