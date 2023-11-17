provider "aws" {

}

# 사용할 수 있는 가용 영역
data "aws_availability_zones" "available" {
  state = "available"
}

# 로컬 변수 선언
locals {
  name     = "module-as"
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
    local.vpc_cidr,
    "0.0.0.0/0" # test
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

# 오토스케일링으로 만들어질 ec2들 설정
resource "aws_launch_configuration" "as_templete" {
  name_prefix   = "${local.name}-asg-"
  image_id      = data.aws_ami.amazon_linux2.id # 사용할 AMI ID를 지정합니다.
  instance_type = "t2.micro"                    # 인스턴스 유형 선택

  security_groups = [module.priv_ingress_sg.security_group_id]

  user_data_base64 = base64encode(local.user_data)
}

# ALB 설정
resource "aws_lb" "alb" {
  name               = "${local.name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.all_ingress_sg.security_group_id]
  subnets            = [for k, v in module.vpc.public_subnets : v]

  # 삭제 방지
  # enable_deletion_protection = true

  tags = merge(
    { Name : "${local.name}-alb" },
    local.tags
  )
}

# 타겟그룹
resource "aws_lb_target_group" "tg" {
  name     = "${local.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

# alb 리스너
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# 오토스케일링 그룹 설정
resource "aws_autoscaling_group" "asg" {
  name_prefix          = "${local.name}-asg-"
  launch_configuration = aws_launch_configuration.as_templete.name
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = [for k, v in module.vpc.private_subnets : v] # 원하는 서브넷 ID 지정
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.tg.arn] # ALB 리소스 이름 지정
}

# autoscaling plicy
resource "aws_autoscaling_policy" "asg_policy" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name                   = "${local.name}_asg_policy"

  adjustment_type         = "ChangeInCapacity"  // 조정 유형 ChangeInCapacity, ExactCapacity, and PercentChangeInCapacity.
  # scaling_adjustment      = 1  // 인스턴스 개수를 증가시킬 양 -> SimpleScaling에서만 지원
  # cooldown                = 300  // 스케일링 이벤트 간의 대기 시간(초) -> SimpleScaling에서만 지원

  // CloudWatch 알람을 통해 CPU 사용률을 확인
  metric_aggregation_type = "Average"  // 지표 집계 유형
  # "SimpleScaling", "StepScaling", "TargetTrackingScaling", or "PredictiveScaling"
  policy_type             = "TargetTrackingScaling"  // 정책 유형

  // CloudWatch 지표 설정
  target_tracking_configuration {
    predefined_metric_specification {
      # ASGTotalCPUUtilization, ASGTotalNetworkIn, ASGTotalNetworkOut, or ALBTargetGroupRequestCount
      predefined_metric_type = "ASGAverageCPUUtilization"  // CloudWatch에서 제공하는 미리 정의된 CPU 사용률 지표
    }
    target_value = 50.0  // CPU 사용률 목표값 (50%)
  }
  
  # target_tracking_configuration {
  #   target_value = 100
  #   customized_metric_specification {
  #     metrics {
  #       label = "Get the queue size (the number of messages waiting to be processed)"
  #       id    = "m1"
  #       metric_stat {
  #         metric {
  #           namespace   = "AWS/SQS"
  #           metric_name = "ApproximateNumberOfMessagesVisible"
  #           dimensions {
  #             name  = "QueueName"
  #             value = "my-queue"
  #           }
  #         }
  #         stat = "Sum"
  #       }
  #       return_data = false
  #     }
  #     metrics {
  #       label = "Get the group size (the number of InService instances)"
  #       id    = "m2"
  #       metric_stat {
  #         metric {
  #           namespace   = "AWS/AutoScaling"
  #           metric_name = "GroupInServiceInstances"
  #           dimensions {
  #             name  = "AutoScalingGroupName"
  #             value = "my-asg"
  #           }
  #         }
  #         stat = "Average"
  #       }
  #       return_data = false
  #     }
  #     metrics {
  #       label       = "Calculate the backlog per instance"
  #       id          = "e1"
  #       expression  = "m1 / m2"
  #       return_data = true
  #     }
  #   }
  # }
}

output "info" {
  value = {
    vpc = {
      azs                         = module.vpc.azs,
      vpc_cidr_block              = module.vpc.vpc_cidr_block,
      private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks,
      private_subnets             = module.vpc.private_subnets,
      public_subnets_cidr_blocks  = module.vpc.public_subnets_cidr_blocks
      public_subnets              = module.vpc.public_subnets
    }
    bastion = {
      for idx, instance in module.bastionEC2 : idx => {
        ami = instance.ami
        az  = instance.availability_zone
        id  = instance.id
      }
    }
    alb = {
      dns_name           = aws_lb.alb.dns_name
      load_balancer_type = aws_lb.alb.load_balancer_type
      subnets            = aws_lb.alb.subnets
    }
    asg = {
      availability_zones = aws_autoscaling_group.asg.availability_zones
      max_size = aws_autoscaling_group.asg.max_size
      min_size = aws_autoscaling_group.asg.min_size
    }
  }
}
