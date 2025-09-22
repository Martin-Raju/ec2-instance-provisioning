variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
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

#variable "instance_types" {
#  description = "List of instance types for the Mixed Instances ASG"
#  type        = list(string)
#}

#variable "default_instance_type" {
#  description = "Default instance type for Launch Template "
#  type        = string
#}

variable "on_demand_percentage_above_base_capacity" {
  description = "Percentage of on-demand capacity above base in Mixed Instances Policy"
  type        = number
}

variable "cpu_target_value" {
  description = "CPU utilization percentage target for scaling policy"
  type        = number
}
