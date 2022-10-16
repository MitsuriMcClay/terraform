provider "aws" {
 profile = "default"
  region = "ap-northeast-1"
  }

resource "aws_vpc" "main" {
cidr_block = "10.0.0.0/16"
 
tags = {
Name = "handson_mitsuri"
}
}

resource "aws_internet_gateway" "IGW" {    # Creating Internet Gateway
 vpc_id =  aws_vpc.main.id               # vpc_id will be generated after we create VPC
 }
 
resource "aws_subnet" "mysubnet" {    # Creating Public Subnets
  vpc_id =  aws_vpc.main.id
   cidr_block = "10.0.0.0/24"        # CIDR block of public subnets
 }

 resource "aws_instance" "example" {
 ami = "ami-0f36dcfcc94112ea1"
 instance_type = "t2.micro"
 subnet_id = aws_subnet.mysubnet.id
 key_name= "key0921"
 associate_public_ip_address  = true
 vpc_security_group_ids = [aws_security_group.allow_ssh_http.id] 
 }

# Security Group

resource "aws_security_group" "allow_ssh_http" {
  vpc_id = aws_vpc.main.id
  name   = "allow_ssh_http"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh_http"
  }
}



 

# Route Table

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "example"
  }
}

resource "aws_route" "example" {
  gateway_id             = aws_internet_gateway.IGW.id
  route_table_id         = aws_route_table.example.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.example.id
}

# アウトバウンドルール(全開放)
resource "aws_security_group_rule" "out_all" {
  security_group_id = aws_security_group.allow_ssh_http.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
}
