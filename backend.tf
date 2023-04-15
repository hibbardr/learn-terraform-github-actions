terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.28.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = ">= 0.14.0"

  cloud {
    organization = "Examples-2"

    workspaces {
      name = "learn-terraform-cloud"
    }
  }
}
#
