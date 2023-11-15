provider "aws" {
  
}

# 사용할 수 있는 가용 영역
data "aws_availability_zones" "available" {
  state = "available"
}

# 로컬 변수 선언
locals {  
  name     = "${basename(path.cwd)}"
  env      = "Dev"
  vpc_cidr = "10.0.0.0/16"
  region   = "ap-northeast-2"
  # 사용가능한 가용영역을 list형태로 slice
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  user_data = <<-EOT
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
  EOT

  tags = {
    Project_Name    = local.name
    Env             = local.env
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24","10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = merge(
    {Name: "${local.name}-vpc"},
    local.tags
  )
}

module "all_ingress_sg" {
  source = "terraform-aws-modules/security-group/aws"
  
  name = "all_ingress_sg"
  description = "This is an SG that allows all ingress."
  vpc_id = module.vpc.vpc_id

  egress_rules = [ "all-all" ]

  ingress_cidr_blocks  = ["0.0.0.0/0"]

  ingress_rules = [ 
    "all-icmp",
    "http-80-tcp",
    "https-443-tcp"
    ]

  tags = merge(
    {Name: "${local.name}-all_ingress_sg"},
    local.tags
  )
}

module "priv_ingress_sg" {
  source = "terraform-aws-modules/security-group/aws"
  
  name = "priv_ingress_sg"
  description = "This is an SG that allows private ingress."
  vpc_id = module.vpc.vpc_id

  egress_rules = [ "all-all" ]

  ingress_cidr_blocks  = [
    local.vpc_cidr
    ]

  ingress_rules = [ 
    "all-icmp",
    "http-80-tcp",
    "https-443-tcp"
    ]

  tags = merge(
    {Name: "${local.name}-priv_ingress_sg"},
    local.tags
  )
}

module "private_sg" {
  source = "terraform-aws-modules/security-group/aws"
  
  name = "private_sg"
  description = "This is an SG that allows private network."
  vpc_id = module.vpc.vpc_id

  egress_rules = [ "all-all" ]

  ingress_cidr_blocks  = [
    module.vpc.vpc_cidr_block,
    "0.0.0.0/0" # test
    ]

  ingress_rules = [ 
    "ssh-tcp"
    ]

  tags = merge(
    {Name: "${local.name}-private_sg"},
    local.tags
  )
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

module "bastionEC2" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  for_each = toset(["1", "2"])

  ami                         = data.aws_ami.amazon_linux2.id
  subnet_id                   = module.vpc.public_subnets[0]
  instance_type               = "t2.micro"
  monitoring                  = true
  associate_public_ip_address = true

  vpc_security_group_ids      = [
      module.all_ingress_sg.security_group_id,
      module.private_sg.security_group_id
    ]
    
  user_data_base64            = base64encode(local.user_data)

  tags = merge(
      {Name: "${local.name}-bastionEC2-${each.key}"},
      local.tags
    )
}

module "privWeb" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  for_each = toset(["1", "2"])

  ami                         = data.aws_ami.amazon_linux2.id
  subnet_id                   = module.vpc.private_subnets[0]
  instance_type               = "t2.micro"
  monitoring                  = true
  # associate_public_ip_address = true

  vpc_security_group_ids      = [
      module.priv_ingress_sg.security_group_id,
      module.private_sg.security_group_id
    ]
    
  user_data_base64            = base64encode(local.user_data)

  tags = merge(
      {Name: "${local.name}-privWeb-${each.key}"},
      local.tags
    )
}