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
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "SubnetA"
  }
}

# 서브넷 (가용 영역 c) 생성
resource "aws_subnet" "subnet_c" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "SubnetC"
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
  subnet_id     = aws_subnet.subnet_a.id

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
resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.route_table_pub.id
}

# 서브넷 (가용 영역 c)에 라우팅 테이블 연결
resource "aws_route_table_association" "subnet_c_association" {
  subnet_id      = aws_subnet.subnet_c.id
  route_table_id = aws_route_table.route_table_priv.id
}

# 보안 그룹 정의 (SSH, HTTP, ICMP 허용)
resource "aws_security_group" "my_sg" {
  name        = "my-security-group"
  description = "My Security Group"
  vpc_id      = aws_vpc.my_vpc.id

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
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySecurityGroup"
  }
}

# EC2 인스턴스 (가용 영역 a) 생성
resource "aws_instance" "ec2_instance_a" {
  ami           = data.aws_ami.amazon_linux2.image_id # 원하는 AMI ID로 변경
  instance_type = "t2.micro"              # 원하는 인스턴스 유형으로 변경
  subnet_id     = aws_subnet.subnet_a.id

  user_data     = <<-EOF
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
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.my_sg.id]

  tags = {
    Name = "EC2InstanceA"
  }
}

# EC2 인스턴스 (가용 영역 c) 생성
resource "aws_instance" "ec2_instance_c" {
  ami           = data.aws_ami.amazon_linux2.image_id # 원하는 AMI ID로 변경
  instance_type = "t2.micro"              # 원하는 인스턴스 유형으로 변경
  subnet_id     = aws_subnet.subnet_c.id

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

  vpc_security_group_ids = [aws_security_group.my_sg.id]

  tags = {
    Name = "EC2InstanceC"
  }
}
