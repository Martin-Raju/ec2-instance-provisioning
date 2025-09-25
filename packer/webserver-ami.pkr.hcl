packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "from_base" {
  region        = "us-east-1"
  source_ami    = "ami-08982f1c5bf93d976"
  instance_type = "t3.micro"
  ssh_username  = "ec2-user"
  ami_name = "packer-ami-from-ec2-{{timestamp}}"
}

build {
  sources = ["source.amazon-ebs.from_base"]
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd git",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd",
      "sudo rm -rf /var/www/html/*",
      "git clone https://github.com/Martin-Raju/web-hosting.git /tmp/html",
      "sudo mv /tmp/html/* /var/www/html",
      "sudo chown -R apache:apache /var/www/html",
      "sudo chmod -R 755 /var/www/html",
	  "sudo systemctl restart httpd"
    ]
  }
}


#source "amazon-ebs" "webserver" {
#  ami_name      = "my-packer-ami-{{timestamp}}"
#  instance_type = "t3.micro"
#  region        = "us-east-1"
#  source_ami_filter {
#    filters = {
#      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
#      root-device-type    = "ebs"
#      virtualization-type = "hvm"
#   }
#    most_recent = true
#    owners      = ["amazon"]
#   }
#  ssh_username = "ubuntu"
#}

#build {
#  sources = ["source.amazon-ebs.webserver"]
#  provisioner "shell" {
#    inline = [
#      "sudo apt-get update",
#      "sudo apt-get install -y nginx",
#      "sudo systemctl enable nginx",
#      "sudo systemctl start nginx"
#    ]
#  }
#}
