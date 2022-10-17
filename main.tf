terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=3.42.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "tfdemo" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.prefix}-vpc-${var.region}"
    environment = "Production"
  }
}

resource "aws_subnet" "tfdemo" {
  vpc_id     = aws_vpc.tfdemo.id
  cidr_block = var.subnet_prefix

  tags = {
    Name = "${var.prefix}-subnet"
  }
}

resource "aws_security_group" "tfdemo" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.tfdemo.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.prefix}-security-group"
  }
}

resource "aws_internet_gateway" "tfdemo" {
  vpc_id = aws_vpc.tfdemo.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_route_table" "tfdemo" {
  vpc_id = aws_vpc.tfdemo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tfdemo.id
  }
}

resource "aws_route_table_association" "tfdemo" {
  subnet_id      = aws_subnet.tfdemo.id
  route_table_id = aws_route_table.tfdemo.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "tfdemo" {
  instance = aws_instance.tfdemo.id
  vpc      = true
  tags = {
    Name = "${var.prefix}-EIP-test"
  }
}

resource "aws_eip_association" "tfdemo" {
  instance_id   = aws_instance.tfdemo.id
  allocation_id = aws_eip.tfdemo.id
}

resource "aws_instance" "tfdemo" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.tfdemo.id
  vpc_security_group_ids      = [aws_security_group.tfdemo.id]

  tags = {
    Name       = "${var.prefix}-test-instance04"
    Department = "SE teams"
    Billable   = "Finance teams"
  }
}
