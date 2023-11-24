provider "aws" {
  region = "ap-northeast-2"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./vpc"
  vpc_cidr_block = "172.16.0.0/16"
}

# module "pub_subnet_1" {
#   source = "./subnet"
#   vpc_id = module.vpc.vpc_id
#   sn_cidr_block = "10.0.1.0/24"
#   az = data.aws_availability_zones.available.names[0]
# }

# module "pub_subnet_2" {
#   source = "./subnet"
#   vpc_id = module.vpc.vpc_id
#   sn_cidr_block = "10.0.2.0/24"
#   az = data.aws_availability_zones.available.names[2]
# }