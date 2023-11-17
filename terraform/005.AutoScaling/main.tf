terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.24.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

data "aws_ami" "amazon_linux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# VPC 생성
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

# 서브넷 (가용 영역 a) 생성
resource "aws_subnet" "subnet_a1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "SubnetA1"
  }
}

# 서브넷 (가용 영역 a) 생성
resource "aws_subnet" "subnet_a2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "SubnetA2"
  }
}

# 서브넷 (가용 영역 c) 생성
resource "aws_subnet" "subnet_c1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "SubnetC1"
  }
}

# 서브넷 (가용 영역 c) 생성
resource "aws_subnet" "subnet_c2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "SubnetC2"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyIGW"
  }
}

# Elastic IP 생성 (NAT 게이트웨이 사용)
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "NATEIP"
  }
}

# NAT 게이트웨이 생성
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet_a1.id

  tags = {
    Name = "NATGateway"
  }
}

# VPC 라우팅 테이블 생성 및 인터넷 연결
resource "aws_route_table" "route_table_pub" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "MyRouteTablePub",
  }
}

# VPC 라우팅 테이블 생성 및 인터넷 연결
resource "aws_route_table" "route_table_priv" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "MyRouteTableNAT",
  }
}

# 서브넷 (가용 영역 a)에 라우팅 테이블 연결
resource "aws_route_table_association" "subnet_a1_association" {
  subnet_id      = aws_subnet.subnet_a1.id
  route_table_id = aws_route_table.route_table_pub.id
}

# 서브넷 (가용 영역 c)에 라우팅 테이블 연결
resource "aws_route_table_association" "subnet_c1_association" {
  subnet_id      = aws_subnet.subnet_c1.id
  route_table_id = aws_route_table.route_table_pub.id
}

# 서브넷 (가용 영역 a)에 라우팅 테이블 연결
resource "aws_route_table_association" "subnet_a2_association" {
  subnet_id      = aws_subnet.subnet_a2.id
  route_table_id = aws_route_table.route_table_priv.id
}

# 서브넷 (가용 영역 c)에 라우팅 테이블 연결
resource "aws_route_table_association" "subnet_c2_association" {
  subnet_id      = aws_subnet.subnet_c2.id
  route_table_id = aws_route_table.route_table_priv.id
}

# 보안 그룹 정의 (SSH, ICMP 허용)
resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "My Security Group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MyPubSecurityGroup"
  }
}

# 보안 그룹 정의 (SSH, HTTP, ICMP 허용)
resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "My Security Group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MyPrivSecurityGroup"
  }
}

# EC2 인스턴스 (가용 영역 a) 생성
resource "aws_instance" "bastionA" {
  ami           = data.aws_ami.amazon_linux2.image_id # 원하는 AMI ID로 변경
  instance_type = "t2.micro"                          # 원하는 인스턴스 유형으로 변경
  subnet_id     = aws_subnet.subnet_a1.id

  user_data                   = <<-EOF
               #!/bin/bash
              echo "password!" | passwd --stdin root
              sed -i "s/^#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
              sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
              systemctl restart sshd
              EOF
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.public_sg.id]

  tags = {
    Name = "bastionA"
  }
}

# --------------------------------------------------------

# 보안 그룹 정의 (SSH, HTTP, ICMP 허용)
resource "aws_security_group" "asg_sg" {
  name        = "asg_sg"
  description = "My Security Group"
  vpc_id      = aws_vpc.my_vpc.id

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

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MyASGSecurityGroup"
  }
}

# 오토스케일링으로 만들어질 ec2들 설정
resource "aws_launch_configuration" "as_templete" {
  name_prefix   = "asg-"
  image_id      = data.aws_ami.amazon_linux2.image_id # 사용할 AMI ID를 지정합니다.
  instance_type = "t2.micro"                          # 인스턴스 유형 선택

  security_groups = [aws_security_group.private_sg.id]

  user_data = <<-EOF
               #!/bin/bash
                echo "password!" | passwd --stdin root
                sed -i "s/^#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
                sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
                systemctl restart sshd
                yum update -y
                yum install -y httpd.x86_64
                systemctl start httpd.service
                systemctl enable httpd.service
                echo "Hello World from $(hostname -f)" > /var/www/html/index.html
              EOF
}

# ALB 설정
resource "aws_lb" "alb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.asg_sg.id]
  subnets            = [aws_subnet.subnet_a1.id, aws_subnet.subnet_c1.id]

  # 삭제 방지
  # enable_deletion_protection = true

  tags = {
    Environment = "dev"
  }
}

# 타겟그룹
resource "aws_lb_target_group" "tg" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

# alb 리스너
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# 오토스케일링 그룹 설정
resource "aws_autoscaling_group" "asg" {
  name_prefix          = "asg-"
  launch_configuration = aws_launch_configuration.as_templete.name
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.subnet_c1.id, aws_subnet.subnet_c2.id] # 원하는 서브넷 ID 지정
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.tg.arn] # ALB 리소스 이름 지정
}

# autoscaling plicy
resource "aws_autoscaling_policy" "example" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name                   = "asg_policy"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    target_value = 100
    customized_metric_specification {
      metrics {
        label = "Get the queue size (the number of messages waiting to be processed)"
        id    = "m1"
        metric_stat {
          metric {
            namespace   = "AWS/SQS"
            metric_name = "ApproximateNumberOfMessagesVisible"
            dimensions {
              name  = "QueueName"
              value = "my-queue"
            }
          }
          stat = "Sum"
        }
        return_data = false
      }
      metrics {
        label = "Get the group size (the number of InService instances)"
        id    = "m2"
        metric_stat {
          metric {
            namespace   = "AWS/AutoScaling"
            metric_name = "GroupInServiceInstances"
            dimensions {
              name  = "AutoScalingGroupName"
              value = "my-asg"
            }
          }
          stat = "Average"
        }
        return_data = false
      }
      metrics {
        label       = "Calculate the backlog per instance"
        id          = "e1"
        expression  = "m1 / m2"
        return_data = true
      }
    }
  }
}

