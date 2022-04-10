
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}


provider "aws" {
default_tags {
   tags = {
     Environment = "development"
     Config      = "magenx"
     Managed     = "terraform"
    }
  }
}
provider "null" {}
provider "random" {}
