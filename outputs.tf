# -------------------------
# Output
# -------------------------

# Get public IPs of instances in the ASG
data "aws_instances" "asg_instances" {
  instance_ids = data.aws_autoscaling_group.asg_info.instances[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of instances in the ASG"
  value       = data.aws_instances.asg_instances.public_ips
}

