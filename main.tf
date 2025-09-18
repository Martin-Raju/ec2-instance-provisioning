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

  # --- Add CloudWatch Agent Setup ---
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update system and install CloudWatch Agent
    yum update -y
    yum install -y amazon-cloudwatch-agent

    # Create CloudWatch Agent config for MemoryUtilization
    cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json << 'EOC'
    {
      "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
      },
      "metrics": {
        "append_dimensions": {
          "AutoScalingGroupName": "spot-asg" 
        },
        "metrics_collected": {
          "mem": {
            "measurement": [
              {"name": "mem_used_percent", "rename": "MemoryUtilization", "unit": "Percent"}
            ],
            "metrics_collection_interval": 60
          }
        }
      }
    }
    EOC

    # Start the CloudWatch Agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
      -s
  EOF
  )
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
    # --- CPU Policy ---
    {
      name                      = "cpu-target-tracking"
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 40
      }
    },
    # --- Memory Policy ---
    {
      name                      = "memory-target-tracking"
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120
      target_tracking_configuration = {
        customized_metric_specification = {
          metric_name = "MemoryUtilization"
          namespace   = "CWAgent"
          statistic   = "Average"
          unit        = "Percent"
          dimensions = {
            AutoScalingGroupName = "spot-asg"
          }
        }
        target_value = 60 # Target average memory utilization %
      }
    }
  ]

}
