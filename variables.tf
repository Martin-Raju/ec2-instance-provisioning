variable "aws_region" {
  description = "aws region"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "max_spot_price" {
  description = "Maximum price for spot instance"
  type        = string
}

variable "environment" {
  type        = string
  description = "dev"
}

variable "key_name" {
  type        = string
  description = "Key pair name for SSH access"
}
