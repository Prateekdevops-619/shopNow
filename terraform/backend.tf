terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Remote state in S3 — bucket must exist before first terraform init
  backend "s3" {
    bucket         = "shopnow-terraform-state-975050024946"
    key            = "shopnow/eks/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "shopnow-terraform-locks"
  }
}
