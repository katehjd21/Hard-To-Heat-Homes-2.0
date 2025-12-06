provider "aws" {
  region = "eu-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "./.ssh/terraform_rsa"
}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "./.ssh/terraform_rsa.pub"
}

resource "aws_vpc" "sandbox_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "sandbox-vpc" }
}

resource "aws_subnet" "sandbox_subnet" {
  vpc_id                  = aws_vpc.sandbox_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH, HTTP, and App"
  vpc_id      = aws_vpc.sandbox_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.sandbox_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = "terraform-key"

  user_data = templatefile("${path.module}/cloud-init.yaml.tmpl", {
    instance_name       = "hard-to-heat-homes-2.0"
    epc_api_key         = var.epc_api_key
    os_api_key          = var.os_api_key
    session_secret_key  = var.session_secret_key
  })

  tags = { Name = "hard-to-heat-homes-2.0" }
}