# -------------------------
# Output
# -------------------------

data "aws_autoscaling_group" "asg_info" {
  name = module.asg.asg_name
}

output "asg_instance_ids" {
  value = data.aws_autoscaling_group.asg_info.instances[*].id
}
