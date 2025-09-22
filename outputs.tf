# -------------------------
# Output
# -------------------------
# --- VPC and Subnets ---
output "vpc_id" {
  description = "Default VPC ID"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "IDs of the default subnets"
  value       = data.aws_subnets.default.ids
}

# --- Security Group ---
output "security_group_id" {
  description = "Security Group ID allowing SSH access"
  value       = module.security_group.security_group_id
}

# --- Auto Scaling Group ---
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_arn
}

output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_id
}

# --- Launch Template ---
output "launch_template_id" {
  description = "ID of the Launch Template created by the ASG module"
  value       = module.asg.launch_template[0].id
}

output "launch_template_name" {
  description = "Name of the Launch Template created by the ASG module"
  value       = module.asg.launch_template[0].name
}

# --- Mixed Instances ---
output "mixed_instances_distribution" {
  description = "Instances distribution configuration for the mixed instances policy"
  value       = module.asg.mixed_instances_policy
}

