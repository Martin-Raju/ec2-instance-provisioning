provider "aws" {
  region = var.aws_region
}

# --------------------------
# Default VPC & Subnets
# --------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
# --------------------------
# Optional Existing ALB
# --------------------------
data "aws_lb" "existing" {
  count = var.create_alb ? 0 : 1
  name  = var.existing_alb_name
}

data "aws_lb_target_group" "existing" {
  count = var.create_alb ? 0 : 1
  name  = var.existing_tg_name
}
# --------------------------
# Check if ASG exists
# --------------------------

data "aws_autoscaling_group" "existing" {
  count = var.existing_asg_name != "" ? 1 : 0
  name  = var.existing_asg_name
}
# --------------------------
# Security Group
# --------------------------
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

# --------------------------
# Capture AMI from running instance
# --------------------------
resource "aws_ami_from_instance" "web_ami" {
  name = "webserver-ami-${formatdate("YYYYMMDDHHMMss", timestamp())}"

  source_instance_id = var.running_instance_id
  description        = "AMI with web server and code"

  tags = {
    Name        = "webserver-ami"
    Environment = var.environment
  }
}
# --------------------------
# Optional ALB
# --------------------------
module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "7.0.0"
  count              = var.create_alb ? 1 : 0
  name               = "web-alb-${substr(timestamp(), 8, 4)}"
  load_balancer_type = "application"
  security_groups    = [module.security_group.security_group_id]
  subnets            = data.aws_subnets.default.ids
  vpc_id             = data.aws_vpc.default.id
  target_groups = [
    {
      name_prefix      = "Web-Tg"
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

# --------------------------
# Create New Launch Template
# --------------------------

resource "aws_launch_template" "web_lt" {
  name_prefix            = "webserver-lt-"
  image_id               = aws_ami_from_instance.web_ami.id
  instance_type          = var.instance_type_p1
  key_name               = var.key_name
  vpc_security_group_ids = [module.security_group.security_group_id]

  #user_data = base64encode(<<-EOT
  #  #!/bin/bash
  # yum install -y stress
  # stress --cpu 3 --timeout 600 &
  #EOT
  #)

  lifecycle {
    create_before_destroy = true
  }
}

# --------------------------
# Create ASG if it doesn't exist
# --------------------------

module "asg" {
  source = "./modules/terraform-aws-autoscaling-8.3.1"
  count  = length(data.aws_autoscaling_group.existing) == 0 ? 1 : 0
  depends_on = [
    aws_ami_from_instance.web_ami,
    aws_launch_template.web_lt
  ]
  name = coalesce(var.existing_asg_name, "webserver-asg")
  #name                       = "Test-server"
  vpc_zone_identifier       = data.aws_subnets.default.ids
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  health_check_type         = "EC2"
  health_check_grace_period = 300
  create_launch_template    = false
  launch_template_id        = aws_launch_template.web_lt.id
  launch_template_version   = "$Latest"
  force_delete              = true
  #launch_template_name       = "spot-lt"
  #image_id                   = aws_ami_from_instance.web_ami.id
  #key_name                   = var.key_name
  #security_groups            = [module.security_group.security_group_id]
  use_mixed_instances_policy = false

  #  user_data = base64encode(<<-EOT
  #    #!/bin/bash
  #    yum install -y stress
  #    stress --cpu 3 --timeout 600 &
  #  EOT
  #  )

  mixed_instances_policy = {
    launch_template = {
      launch_template_specification = {
        launch_template_name = aws_launch_template.web_lt.name
        version              = "$Latest"
      }
    }
    instances_distribution = {
      base_capacity                            = 0
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
      spot_allocation_strategy                 = "lowest-price"
      on_demand_allocation_strategy            = "prioritized"
      spot_instance_pools                      = 4
      #spot_max_price                           = var.spot_max_price
    }

    override = [
      { instance_type = var.instance_type_p1, spot_price = var.spot_price_p1 },
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

# --------------------------
# Update Existing ASG Launch Template
# --------------------------
resource "aws_autoscaling_group" "update_asg_lt" {
  count = length(data.aws_autoscaling_group.existing) > 0 ? 1 : 0
  name  = data.aws_autoscaling_group.existing[0].name

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  min_size                  = data.aws_autoscaling_group.existing[0].min_size
  max_size                  = data.aws_autoscaling_group.existing[0].max_size
  desired_capacity          = data.aws_autoscaling_group.existing[0].desired_capacity
  vpc_zone_identifier       = data.aws_autoscaling_group.existing[0].vpc_zone_identifier
  health_check_type         = data.aws_autoscaling_group.existing[0].health_check_type
  health_check_grace_period = data.aws_autoscaling_group.existing[0].health_check_grace_period
  force_delete              = true

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }
}

# --------------------------
# Local Target Group ARN
# --------------------------

locals {
  alb_target_group_arn = var.create_alb ? module.alb[0].target_group_arns[0] : data.aws_lb_target_group.existing[0].arn
}

# --------------------------
# Attach ASG to Target Group
# --------------------------
resource "aws_autoscaling_attachment" "asg_alb" {
  autoscaling_group_name = (
    length(data.aws_autoscaling_group.existing) > 0 ?
    data.aws_autoscaling_group.existing[0].name :
    module.asg[0].autoscaling_group_name
  )
  lb_target_group_arn = local.alb_target_group_arn

  depends_on = [
    module.asg,
    module.alb
  ]
}