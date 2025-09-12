# -------------------------
# Output
# -------------------------
output "instance_public_ip" {
  value = aws_instance.spot_worker.public_ip
}
