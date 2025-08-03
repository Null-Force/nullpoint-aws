# Provider configurations

terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project            = "nullforce-kickstart-aws"
      Component          = "nullpoint-aws"
      ManagedBy          = "Terraform"
    }
  }
}