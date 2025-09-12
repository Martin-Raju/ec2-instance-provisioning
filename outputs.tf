# -------------------------
# Output
# -------------------------
output "instance_public_ip" {
  value = aws_instance.cheap_worker.public_ip
}