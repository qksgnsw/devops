resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_groups # RDS가 위치할 서브넷 ID 입력
}

resource "aws_db_instance" "this" {
  db_subnet_group_name = aws_db_subnet_group.this.name

  allocated_storage    = 10
  db_name              = var.name
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = var.username
  password             = var.password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = var.sg

  tags = var.tags
}