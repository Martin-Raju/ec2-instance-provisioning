terraform {
  backend "s3" {
    bucket  = "my-tfstate-bucket-0123456"
    key     = "ENV/Test/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
