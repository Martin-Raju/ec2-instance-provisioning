# -------------------------
# Output
# -------------------------
# ASG ID
output "asg_id" {
  description = "The ID of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_id
}

# Launch Template ID 
output "launch_template_id" {
  description = "The ID of the Launch Template"
  value       = module.asg.launch_template_id
}

# ASG Instance IDs
output "asg_instance_ids" {
  description = "List of instance IDs in the Auto Scaling Group"
  value       = module.asg.instances
}

# Security Group ID
output "security_group_id" {
  description = "The ID of the security group created"
  value       = module.security_group.security_group_id
}
