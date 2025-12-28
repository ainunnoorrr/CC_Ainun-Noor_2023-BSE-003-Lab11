provider "aws" {
  region                   = "me-central-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "availability_zone" {}
variable "env_prefix" {}

variable "my_ip" {}
variable "public_key_location" {}
variable "ami_id" {}

resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block
  tags       = { Name = "${var.env_prefix}-vpc" }
}

resource "aws_subnet" "myapp_subnet_1" {
  vpc_id                  = aws_vpc.myapp_vpc.id
  cidr_block              = var.subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.env_prefix}-subnet-1" }
}

resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp_vpc.id
  tags   = { Name = "${var.env_prefix}-igw" }
}

resource "aws_default_route_table" "main_rt" {
  default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }

  tags = { Name = "${var.env_prefix}-main-rt" }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "serverkey"
  public_key = file(pathexpand(var.public_key_location))
}

resource "aws_security_group" "myapp_sg" {
  name   = "${var.env_prefix}-sg"
  vpc_id = aws_vpc.myapp_vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.env_prefix}-sg" }
}

resource "aws_instance" "myapp_server" {
  ami                         = trimspace(var.ami_id)
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.myapp_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.myapp_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh_key.key_name

  user_data                   = file("entry-script.sh")
  user_data_replace_on_change = true

  tags = { Name = "${var.env_prefix}-server" }
}

output "ec2_public_ip" {
  value = aws_instance.myapp_server.public_ip
}
