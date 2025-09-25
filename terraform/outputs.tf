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
# Security Group ID
output "security_group_id" {
  description = "The ID of the security group created"
  value       = module.security_group.security_group_id
}
# Ami_id
output "ami_id" {
  value = var.ami_id
}

output "subnet_ids" {
  value = data.aws_subnets.default.ids
}