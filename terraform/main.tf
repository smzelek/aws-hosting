terraform {
  backend "s3" {
    bucket = "kerukion-terraform"
    key    = "kerukion-terraform/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = local.aws_region
}

resource "aws_ecr_repository" "default_image" {
  name = "default-image"
}

