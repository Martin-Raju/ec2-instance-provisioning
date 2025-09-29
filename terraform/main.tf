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
  name        = "allow_web"
  description = "Allow HTTP/SSH inbound traffic"
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

# Capture AMI from running instance
resource "aws_ami_from_instance" "web_ami" {
  name = "webserver-ami-${formatdate("YYYYMMDDHHMM", timestamp())}"

  source_instance_id = var.running_instance_id
  description        = "AMI with web server and code"

  tags = {
    Name        = "webserver-ami"
    Environment = var.environment
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "7.0.0"

  name               = "web-alb"
  load_balancer_type = "application"
  security_groups    = [module.security_group.security_group_id]
  subnets            = data.aws_subnets.default.ids
  vpc_id             = data.aws_vpc.default.id

  target_groups = [
    {
      name_prefix      = "web-tg"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        path                = "/"
        protocol            = "HTTP"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 30
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
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
  image_id                   = aws_ami_from_instance.web_ami.id
  key_name                   = var.key_name
  security_groups            = [module.security_group.security_group_id]
  use_mixed_instances_policy = true

  user_data = base64encode(<<-EOT
    #!/bin/bash
    yum install -y stress
    stress --cpu 3 --timeout 600 &
  EOT
  )

  mixed_instances_policy = {
    instances_distribution = {
      base_capacity                            = 0
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
      spot_allocation_strategy                 = "lowest-price"
      on_demand_allocation_strategy            = "prioritized"
      spot_instance_pools                      = 4
      #spot_max_price                           = var.spot_max_price
    }

    override = [
      #    { instance_type = var.instance_type_p1, spot_price = var.spot_price_p1 },
      { instance_type = var.instance_type_p2, spot_price = var.spot_price_p2 },
      { instance_type = var.instance_type_p3, spot_price = var.spot_price_p3 },
      { instance_type = var.instance_type_p4, spot_price = var.spot_price_p4 }
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
# --- Attach ASG to Target Group ---

resource "aws_autoscaling_attachment" "asg_alb" {
  autoscaling_group_name = module.asg.autoscaling_group_name
  lb_target_group_arn    = module.alb.target_group_arns[0]
}