terraform {
  backend "s3" {
    bucket = "mmc-full-stack-app-terraform-state-bucket-mmc"
    key    = "eb/terraform.tfstate"
    region = "us-east-1"
  }
}