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
# Create a new VPC block
resource "aws_vpc" "Terraformlab" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
# Create internet gateway
resource "aws_internet_gateway" "Terraformlab" {
  vpc_id = aws_vpc.Terraformlab.id
}
# Create Public Route Table
resource "aws_route_table" "Terraformlab" {
  vpc_id = aws_vpc.Terraformlab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Terraformlab.id
  }
}
# Make two subnets
resource "aws_subnet" "Terraformlab-public-1" {
  vpc_id                  = aws_vpc.Terraformlab.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "Terraformlab-public-2" {
  vpc_id                  = aws_vpc.Terraformlab.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}
# Associate the subnets with route table
resource "aws_route_table_association" "public-access-1" {
  subnet_id      = aws_subnet.Terraformlab-public-1.id
  route_table_id = aws_route_table.Terraformlab.id
}

resource "aws_route_table_association" "public-access-2" {
  subnet_id      = aws_subnet.Terraformlab-public-2.id
  route_table_id = aws_route_table.Terraformlab.id
}
# Make a security group
resource "aws_security_group" "Terraformlab" {
  name        = "TerraformLab-SG"
  description = "allow SSH and HTTP"
  vpc_id      = aws_vpc.Terraformlab.id
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow Everything"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Deploy an EC2 instace
resource "aws_instance" "EC2-1" {
  ami             = "ami-01fb3cd2c71298dfd"
  instance_type   = "t2.micro"
  key_name        = "Keys"
  subnet_id       = aws_subnet.Terraformlab-public-1.id
  security_groups = [aws_security_group.Terraformlab.id]
  user_data       = <<-EOF
                #!/bin/bash
                yum update -y
                yum install httpd -y
                cd /var/www/html
                echo "<html><body><h1> Hello from your favourite students at $(hostname -f)<//h1></body></html>">index.html
                systemctl restart httpd
                systemctl enable httpd
                EOF
}
resource "aws_instance" "EC2-2" {
  ami             = "ami-01fb3cd2c71298dfd"
  instance_type   = "t2.micro"
  key_name        = "Keys"
  subnet_id       = aws_subnet.Terraformlab-public-2.id
  security_groups = [aws_security_group.Terraformlab.id]
  user_data       = <<-EOF
                #!/bin/bash
                yum update -y
                yum install httpd -y
                cd /var/www/html
                echo "<html><body><h1> Hello from your favourite students at $(hostname -f)<//h1></body></html>">index.html
                systemctl restart httpd
                systemctl enable httpd
                EOF
}
# Create Load balancer

resource "aws_lb" "alb" {
  name               = "T-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Terraformlab.id]

  subnets = [
    aws_subnet.Terraformlab-public-1.id,
    aws_subnet.Terraformlab-public-2.id,
  ]
}
# Create Listener for load balancer

resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    type             = "forward"
  }
}
# Create alb target group for load balancer

resource "aws_lb_target_group" "alb_target_group" {
  name_prefix = "my-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.Terraformlab.id
  health_check {
    path = "/"
  }
}
# Register EC2 instances to target group

resource "aws_lb_target_group_attachment" "lab-1" {
  target_group_arn = aws_lb_target_group.alb_target_group.id
  target_id        = aws_instance.EC2-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "lab-2" {
  target_group_arn = aws_lb_target_group.alb_target_group.id
  target_id        = aws_instance.EC2-2.id
  port             = 80
}
#This is a commit to show roll back
