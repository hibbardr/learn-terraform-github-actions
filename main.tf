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
provider "aws" {
  region     = "us-east-1"
  access_key = "ASIA35KEIHUNNNUXYUKN"
  secret_key = "+v1InWjEn4+zIzuLYA0ao+yiFgZVA0ZhPEvRz/iN"
  token      = "FwoGZXIvYXdzEB4aDICq/A84Wr97ECPjkCLJAZRYUFn7RymPFcvto/sr+pgl/bZBB7Es23/0B8xdRFUzq9aD4Q4/inzDSum2oc0HnE7zo+VobUO4WMhI4S6JdVSpItj+LHLdZvCeUc9Lm2jlPMwqxZ2bcpFuVBsh8wlF/FxulcwKhCcqg601GB3gNhnEj67b0l8kcJtkFl7MZJLw3mOHJDyturR6UGO+4y+fQ9ZChlAn79XfwkzBrgETsw4omk7K641aJYuu4Ar9kW0li5dL/ChBUHmwVz153ek+Vu2SOKCcX2SMiSiw5OahBjItw7X8QXRER6TyOZlrq7Uqzp7U9AO+ETPlXlRukzST2OeJa4Hed0RYHbDsLRSs"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}
