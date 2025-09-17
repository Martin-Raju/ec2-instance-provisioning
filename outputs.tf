# -------------------------
# Output
# -------------------------

output "spot_ids" {
  description = "EC2 instance IDs or Spot Request IDs depending on state"
  value = {
    for k, m in module.spot_instance : k => m.id
  }
}

output "instance_public_ips" {
  description = "Public IPs of the instances"
  value = {
    for k, m in module.spot_instance : k => m.public_ip
  }
}
