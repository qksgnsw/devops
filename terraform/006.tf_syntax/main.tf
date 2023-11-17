# Terraform Block
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

# Provider Block
provider "local" {

}

# Resouce Block
resource "local_file" "resouce_id" {
  content  = "This is Text text."
  filename = "${path.module}/test.txt"
}

# Data Block
data "local_file" "data_id" {
  filename = "${path.module}/test.txt"
}

# Output Block
output "output_key" {
  value = data.local_file.data_id
}

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name        = "main"
    Environment = "Dev"
    Change      = "1"
  }
}

output "main" {
  value = aws_vpc.main
}

data "aws_vpcs" "main" {}

output "vpc_data" {
  value = data.aws_vpcs.main
}