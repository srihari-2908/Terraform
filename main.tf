# Creating a VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "MultiTierVPC"
  }
}

# Creating Public Subnets
resource "aws_subnet" "public_subnets" {
  for_each                = zipmap(var.public_subnet_cidrs, var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.key
  map_public_ip_on_launch = true
  availability_zone       = each.value

  tags = {
    Name = "PublicSubnet-${each.key}"
  }
}

# Creating Private Subnets
resource "aws_subnet" "private_subnets" {
  for_each          = zipmap(var.private_subnet_cidrs, var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.key
  availability_zone = each.value

  tags = {
    Name = "PrivateSubnet-${each.key}"
  }
}

# Creating Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MainIGW"
  }
}

# Reserving a static, public IP address that can be associated with the NAT Gateway.
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "NAT-EIP"
  }
}

# Creating NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = values(aws_subnet.public_subnets)[0].id
  tags = {
    Name = "NATGW"
  }
}

# Route Tables for public segment with igw
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRT"
  }
}

# Route Tables for private segment with nat gtwy
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "PrivateRT"
  }
}


# Route Table Associations
resource "aws_route_table_association" "public_rta" {
  for_each      = aws_subnet.public_subnets
  subnet_id     = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

# Route Table Associations
resource "aws_route_table_association" "private_rta" {
  for_each      = aws_subnet.private_subnets
  subnet_id     = each.value.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.main.id

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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "LBSecurityGroup"
  }
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2SecurityGroup"
  }
}

# Launch Configuration
resource "aws_launch_template" "web_lc" {
  name_prefix          = "web-lc"
  image_id             = "ami-0261755bbcb8c4a84"
  instance_type        = "t2.micro"
  user_data            = base64encode(file("userdata.sh"))

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
    associate_public_ip_address = true
  }

  tags = {
    Name = "WebInstance"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  launch_template {
    id      = aws_launch_template.web_lc.id
    version = "$Latest"
  }
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2

  vpc_zone_identifier = [
    aws_subnet.private_subnets["10.0.3.0/24"].id,
    aws_subnet.private_subnets["10.0.4.0/24"].id
  ]

  tag {
      key = "Name"
      value = "WebServer"
      propagate_at_launch = true
    }
}

# Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = values(aws_subnet.public_subnets)[*].id

  tags = {
    Name = "AppLoadBalancer"
  }
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app_tg.arn
    type             = "forward"
  }
}

# Attach Auto Scaling Instances to Target Group
resource "aws_autoscaling_attachment" "asg_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.id
  lb_target_group_arn       = aws_lb_target_group.app_tg.arn
}
