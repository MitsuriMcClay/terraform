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
  availability_zone = "ap-northeast-1a"
 }

resource "aws_subnet" "mysubnet_2" {    # Creating Public Subnets
  vpc_id =  aws_vpc.main.id
   cidr_block = "10.0.1.0/24"        # CIDR block of public subnets
  availability_zone = "ap-northeast-1c"
 }

resource "aws_instance" "example" {
   count = 2
   tags = {
    Name = "test-instance-${count.index}"
    }
   ami = "ami-0f36dcfcc94112ea1"
   instance_type = "t2.micro"
   subnet_id = aws_subnet.mysubnet.id
   key_name= "key0921"
   associate_public_ip_address  = true
   vpc_security_group_ids = [aws_security_group.allow_ssh_http.id] 

   provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user  -i '${self.public_ip},' --private-key ../Ansible_testproject/key0921.pem  ../Ansible_testproject/install_nginx.yml"
  }
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
    from_port = var.port
    to_port = var.port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh_http"
  }
}

#Load Balancer

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh_http.id]
  subnets            = [aws_subnet.mysubnet.id, aws_subnet.mysubnet_2.id]
}


# Route Table

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "example"
  }
}

#Target Group
resource "aws_lb_target_group" "alb-example" {
  name        = "tf-example-lb-alb-tg"
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
}

#Target Group Attachment
resource "aws_lb_target_group_attachment" "alb-example_attach" {
  count = 2
  target_group_arn = aws_lb_target_group.alb-example.arn
  target_id        = aws_instance.example[count.index].id
  port             = var.port
}

#ALB Listner
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = var.port
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-example.arn
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
