    # Example for an AWS AMI
    packer {
      required_plugins {
        amazon = {
          source  = "github.com/hashicorp/amazon"
          version = "~> 1"
        }
      }
    }

    source "amazon-ebs" "webserver" {
      ami_name      = "my-packer-ami-{{timestamp}}"
      instance_type = "t2.micro"
      region        = "us-east-1"
      source_ami_filter {
        filters = {
          name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
          root-device-type    = "ebs"
          virtualization-type = "hvm"
        }
        most_recent = true
        owners      = ["amazon"]
      }
      ssh_username = "ubuntu"
    }

    build {
      sources = ["source.amazon-ebs.webserver"]
      provisioner "shell" {
        inline = [
          "sudo apt-get update",
          "sudo apt-get install -y nginx",
          "sudo systemctl enable nginx",
          "sudo systemctl start nginx"
        ]
      }
    }