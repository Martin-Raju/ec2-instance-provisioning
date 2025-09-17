# -------------------------
# Output
# -------------------------
output "instance_ids" {
  description = "IDs of all Spot instances"
  value = {
    for k, m in module.spot_instance : k => m.id
  }
}

output "instance_public_ips" {
  description = "Public IPs of all Spot instances"
  value = {
    for k, m in module.spot_instance : k => m.public_ip
  }
}

