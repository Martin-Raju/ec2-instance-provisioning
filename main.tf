provider "aws" {
  region = var.aws_region
}

# -------------------------
# Networking - Security Group
# -------------------------
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to your IP for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# -------------------------
# Get default VPC and Subnet
# -------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# -------------------------
# Spot Instance
# -------------------------
resource "aws_instance" "spot_worker" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = element(data.aws_subnet_ids.default.ids, 0)
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = "test01"

  # Request a Spot Instance
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.max_spot_price
    }
  }

  tags = {
    Name = "Ec2-Spot"
  }
}
