# Variable Block
variable "pjt_name" {
  type = string
  default = "test"
}
variable "region" {
  type = string
  default = "ap-northeast-2"
}
variable "vpc_cidr_block" {
  type = string
  default = "10.0.0.0/16"
}