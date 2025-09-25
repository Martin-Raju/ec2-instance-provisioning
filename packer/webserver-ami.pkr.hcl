packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "from_running_instance" {
  region        = "us-east-1"
  source_ami    = "ami-08982f1c5bf93d976"
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"

  ami_name = "packer-ami-from-ec2-{{timestamp}}"
}

build {
  sources = ["source.amazon-ebs.from_running_instance"]
}
