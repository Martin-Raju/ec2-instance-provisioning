# -------------------------
# Output
# -------------------------
output "instance_id" {
  value = module.spot_instance.id
}

output "instance_public_ip" {
  value = module.spot_instance.public_ip
}
