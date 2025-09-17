# -------------------------
# Output
# -------------------------

output "spot_instance_ids" {
  value = { for k, m in module.spot_instance : k => m.spot_instance_id }
}

output "instance_public_ips" {
  value = { for k, m in module.spot_instance : k => m.public_ip }
}

