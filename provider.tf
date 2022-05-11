terraform {
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.11.0"
    }
  }

  # required_version = ">= 1.2.0, < 2.0.0"
}

provider "aws" {
  region  = "us-east-1"
}

provider "github" {
  token = var.github_token
}
