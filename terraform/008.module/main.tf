provider "aws" {
  
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "Module-test"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
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

  tags = {
    Name = "all_ingress_sg"
    Terraform = "true"
    Environment = "dev"
  }
}

module "private_sg" {
  source = "terraform-aws-modules/security-group/aws"
  
  name = "private_sg"
  description = "This is an SG that allows private network."
  vpc_id = module.vpc.vpc_id

  egress_rules = [ "all-all" ]

  ingress_cidr_blocks  = [module.vpc.vpc_cidr_block]

  ingress_rules = [ 
    "ssh-tcp"
    ]

  tags = {
    Name = "private_sg"
    Terraform = "true"
    Environment = "dev"
  }
}