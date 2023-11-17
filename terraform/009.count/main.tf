terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 사용자 계정 생성
resource "aws_iam_user" "user_1" {
  name = "user_1"
}

resource "aws_iam_user" "user_2" {
  name = "user_2"
}

resource "aws_iam_user" "user_3" {
  name = "user_3"
}

output "user_arn" {
  value = [
    aws_iam_user.user_1.arn,
    aws_iam_user.user_2.arn,
    aws_iam_user.user_3.arn,
  ]
}

resource "aws_iam_user" "admins" {
  count = 3
  name  = "admin.${count.index}"
}

output "admins_arn" {
  value = aws_iam_user.admins.*.arn
}

resource "aws_iam_user" "for_each_user" {
  for_each = toset([
    "test1",
    "test2",
    "test3",
  ])

  name = "user-${each.value}"
}

output "for_each_user" {
  value = values(aws_iam_user.for_each_user).*.arn
}

resource "aws_iam_user" "foreachandmap" {
  for_each = {
    kim = {
      name       = "kim"
      level      = "admin"
      department = "dev"
    }
    lee = {
      name       = "lee"
      level      = "A"
      department = "dev2"
    }
    park = {
      name       = "park"
      level      = "B"
      department = "dev3"
    }
  }
  name = each.key
  tags = each.value
}

output "foreachandmap" {
  value = values(aws_iam_user.foreachandmap).*.arn
}