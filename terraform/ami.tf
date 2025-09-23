resource "aws_instance" "webserver" {
  ami             = var.ami_id
  instance_type   = "t3.micro"
  key_name        = var.key_name
  security_groups = [module.security_group.security_group_id]

  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Welcome to your custom web server on $(hostname)</h1>" > /var/www/html/index.html
  EOT

  tags = {
    Name = "TempWebServer"
  }
}

resource "aws_ami_from_instance" "webserver_ami" {
  name                    = "custom-webserver-ami-${timestamp()}"
  source_instance_id      = aws_instance.webserver.id
  snapshot_without_reboot = true
  tags = {
    Name = "CustomWebServerAMI"
  }
}

