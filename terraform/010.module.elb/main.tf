provider "aws" {

}

# 사용할 수 있는 가용 영역
data "aws_availability_zones" "available" {
  state = "available"

  # filter {
  #   name   = "opt-in-status"
  #   values = ["opt-in-not-required"]
  # }

  # filter {
  #   name   = "opt-in-status"
  #   values = ["not-opted-in", "opted-in"]
  # }
}

# 로컬 변수 선언
locals {
  # name     = basename(path.cwd)
  name     = "Project-01"
  env      = "Dev"
  vpc_cidr = "10.0.0.0/16"
  region   = "ap-northeast-2"
  # 사용가능한 가용영역을 list형태로 slice
  # slice(list, start_index, end_index)
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

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
    Project_Name = local.name
    Env          = local.env
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  # azs             = local.azs
  # t2.micro는 a,c만 가능
  azs = ["${local.region}a", "${local.region}c"]
  # cidrsubnet(network_address, newbits, netnum)
  # local.vpc_cidr이 10.0.0.0/16이라고 가정하면, 
  # cidrsubnet(local.vpc_cidr, 8, k)는 이를 8 비트씩 세분화하여 서브넷을 만들고 
  # 각각의 서브넷을 public_subnets 리스트에 추가합니다.
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 100)]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = merge(
    { Name : "${local.name}-vpc" },
    local.tags
  )
}

output "vpc_info" {
  value = {
    azs                         = module.vpc.azs,
    vpc_cidr_block              = module.vpc.vpc_cidr_block,
    private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks,
    private_subnets             = module.vpc.private_subnets,
    public_subnets_cidr_blocks  = module.vpc.public_subnets_cidr_blocks
    public_subnets              = module.vpc.public_subnets
  }
}

module "all_ingress_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "all_ingress_sg"
  description = "This is an SG that allows all ingress."
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]

  ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_rules = [
    "all-icmp",
    "http-80-tcp",
    "https-443-tcp"
  ]

  tags = merge(
    { Name : "${local.name}-all_ingress_sg" },
    local.tags
  )
}

module "priv_ingress_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "priv_ingress_sg"
  description = "This is an SG that allows private ingress."
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]

  ingress_cidr_blocks = [
    local.vpc_cidr
  ]

  ingress_rules = [
    "all-icmp",
    "http-80-tcp",
    "https-443-tcp"
  ]

  tags = merge(
    { Name : "${local.name}-priv_ingress_sg" },
    local.tags
  )
}

module "private_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "private_sg"
  description = "This is an SG that allows private network."
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]

  ingress_cidr_blocks = [
    module.vpc.vpc_cidr_block,
    "0.0.0.0/0" # test
  ]

  ingress_rules = [
    "ssh-tcp"
  ]

  tags = merge(
    { Name : "${local.name}-private_sg" },
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
  source = "terraform-aws-modules/ec2-instance/aws"

  count = 2

  ami                         = data.aws_ami.amazon_linux2.id
  subnet_id                   = module.vpc.public_subnets[count.index]
  instance_type               = "t2.micro"
  monitoring                  = true
  associate_public_ip_address = true

  vpc_security_group_ids = [
    module.all_ingress_sg.security_group_id,
    module.private_sg.security_group_id
  ]

  user_data_base64 = base64encode(local.user_data)

  tags = merge(
    { Name : "${local.name}-bastionEC2-${count.index}" },
    local.tags
  )
}

module "privWeb" {
  source = "terraform-aws-modules/ec2-instance/aws"

  count = 2

  ami           = data.aws_ami.amazon_linux2.id
  subnet_id     = module.vpc.private_subnets[count.index]
  instance_type = "t2.micro"
  monitoring    = true
  # associate_public_ip_address = true

  vpc_security_group_ids = [
    module.priv_ingress_sg.security_group_id,
    module.private_sg.security_group_id
  ]

  user_data_base64 = base64encode(local.user_data)

  tags = merge(
    { Name : "${local.name}-privWeb-${count.index}" },
    local.tags
  )
}

output "bastion_info" {
  value = {
    for idx, instance in module.bastionEC2 : idx => {
      ami = instance.ami
      az  = instance.availability_zone
      id  = instance.id
    }
  }
}

output "privweb_info" {
  value = {
    for idx, instance in module.privWeb : idx => {
      ami = instance.ami
      az  = instance.availability_zone
      id  = instance.id
    }
  }
}

module "elb_http" {
  source = "terraform-aws-modules/elb/aws"

  name = local.name

  # depends_on = [module.vpc, module.privWeb]

  subnets = module.vpc.public_subnets
  security_groups = [
    module.all_ingress_sg.security_group_id
  ]
  internal = false

  listener = [
    {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    },
    # {
    #   instance_port     = 8080
    #   instance_protocol = "http"
    #   lb_port           = 8080
    #   lb_protocol       = "http"
    #   ssl_certificate_id = "arn:aws:acm:eu-west-1:235367859451:certificate/6c270328-2cd5-4b2d-8dfd-ae8d0004ad31"
    # },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  # access_logs = {
  #   bucket = "my-access-logs-bucket"
  # }

  // ELB attachments
  number_of_instances = 2
  instances           = [for k in module.privWeb : k.id]

  tags = merge(
    { Name : "${local.name}-elb" },
    local.tags
  )
}
