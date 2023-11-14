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

# VPC 생성
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC"
  }
}

# 서브넷 (가용 영역 a)
resource "aws_subnet" "subnet_a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "SubnetA",
  }
}

# 서브넷 (가용 영역 c)
resource "aws_subnet" "subnet_c" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "SubnetC",
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyIGW",
  }
}

# VPC 라우팅 테이블 생성 및 인터넷 연결
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MyRouteTable",
  }
}

# 서브넷 (가용 영역 a)에 라우팅 테이블 연결
resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.route_table.id
}

# 서브넷 (가용 영역 c)에 라우팅 테이블 연결
resource "aws_route_table_association" "subnet_c_association" {
  subnet_id      = aws_subnet.subnet_c.id
  route_table_id = aws_route_table.route_table.id
}
