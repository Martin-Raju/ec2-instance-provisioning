# Amazon EBS source
source "amazon-ebs" "webserver" {
  region            = var.aws_region
  instance_type     = "t3.micro"
  ami_name          = var.ami_name
  ssh_username      = "ec2-user"

  # Amazon Linux 2 base AMI
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }
}

build {
  name    = "webserver-ami-build"
  sources = ["source.amazon-ebs.webserver"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd",
      "echo '<h1>Welcome to your custom web server on $(hostname)</h1>' | sudo tee /var/www/html/index.html"
    ]
  }
}
