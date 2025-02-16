###################### Create VPC (10.0.0.0/16) #################################

resource "aws_vpc" "terraform_vpc" {
    cidr_block = "10.0.0.0/16"
    
    tags = {
    Name = "terraform_vpc"
  }
}


###################### Create IG #################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "igw"
  }
}

###################### Create 2 Subnets #################################

resource "aws_subnet" "subnets" {
  for_each = var.subnets_value

  vpc_id     = aws_vpc.terraform_vpc.id
  
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key
  }
}

###################### Create RT #################################


resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
 
  tags = {
    Name = "RT"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnets["subnet-1"].id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnets["subnet-2"].id
  route_table_id = aws_route_table.RT.id
}


###################### Create Security Group #################################

resource "aws_security_group" "SG" {
  name        = "SG"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  tags = {
    Name = "SG"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_443" {
  security_group_id = aws_security_group.SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_80" {
  security_group_id = aws_security_group.SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

###################### Create 2 EC2 #################################

resource "aws_instance" "instances" {
    for_each = {
    instance-1 = "subnet-1"
    instance-2 = "subnet-2"
  }


    ami = "ami-0ddfba243cbee3768"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.SG.id]
    associate_public_ip_address = true
    subnet_id = aws_subnet.subnets[each.value].id
    

      user_data = <<-EOF
              #!/bin/bash

              ########################################
              ##### USE THIS WITH AMAZON LINUX 2 #####
              ########################################

              # get admin privileges
              sudo su

              # install httpd (Linux 2 version)
              yum update -y
              yum install -y httpd.x86_64
              systemctl start httpd.service
              systemctl enable httpd.service
              echo "Hello World from $(hostname -f)" > /var/www/html/index.html
              EOF

  tags = {
    Name = each.key
  }

  
}


###################### Create Target Group #################################

resource "aws_lb_target_group" "TG" {
  name     = "TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_vpc.id
}

resource "aws_lb_target_group_attachment" "test"{
  target_group_arn = aws_lb_target_group.TG.id
  target_id        = aws_instance.instances["instance-1"].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "test1" {
  target_group_arn = aws_lb_target_group.TG.id
  target_id        = aws_instance.instances["instance-2"].id
  port             = 80
}

###################### ALB ################################

resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SG.id]
  subnets            = [aws_subnet.subnets["subnet-1"].id, aws_subnet.subnets["subnet-2"].id]
  

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG.arn
  }
}