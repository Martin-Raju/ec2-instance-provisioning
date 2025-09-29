variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "running_instance_id" {
  description = "ID of the running instance to capture AMI from"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
}

#variable "instance_type_p1" {
#  description = "List of instance types for the Mixed Instances ASG"
# type        = string
#}

variable "instance_type_p2" {
  description = "List of instance types for the Mixed Instances ASG"
  type        = string
}

variable "instance_type_p3" {
  description = "List of instance types for the Mixed Instances ASG"
  type        = string
}

variable "instance_type_p4" {
  description = "List of instance types for the Mixed Instances ASG"
  type        = string
}

#variable "spot_max_price" {
#  description = "Default instance type for Launch Template "
#  type        = number
#}

variable "on_demand_percentage_above_base_capacity" {
  description = "Percentage of on-demand capacity above base in Mixed Instances Policy"
  type        = number
}

variable "cpu_target_value" {
  description = "CPU utilization percentage target for scaling policy"
  type        = number
}

#variable "spot_price_p1" {
#  description = "Default instance type for Launch Template "
#  type        = number
#}

variable "spot_price_p2" {
  description = "Default instance type for Launch Template "
  type        = number
}

variable "spot_price_p3" {
  description = "Default instance type for Launch Template "
  type        = number
}

variable "spot_price_p4" {
  description = "Default instance type for Launch Template "
  type        = number
}

variable "create_alb" {
  description = "Whether to create a new ALB (true) or use an existing one (false)"
  type        = bool
}

variable "existing_alb_name" {
  description = "Name of existing ALB to use if create_alb=false"
  type        = string
}

variable "existing_tg_name" {
  description = "Name of existing Target Group to use if create_alb=false"
  type        = string
}