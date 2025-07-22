# TO RUN:
# terraform init
# terraform plan
# terraform apply --auto-approve
# terraform destroy

locals {
  arquiebrio = "jcatica"
  image = ""
  vpc_id = ""
  subnets = []
}

terraform {
  required_version = ">= 1.8.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# Security Group
# ---------------------------

resource "aws_security_group" "alb_sg" {
  name = "sg-alb-mcp-arquipuntos-${local.arquiebrio}"

  vpc_id = aws_vpc.main.id #######
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# ALB
# ---------------------------

resource "aws_lb" "alb" {
  name               = "alb-mcp-arquipuntos-${local.arquiebrio}"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.main.id] #######
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "ecs_tg" {
  name     = "alb-tg-mcp-arquipuntos-${local.arquiebrio}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id #######
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

# ---------------------------
# IAM Role
# ---------------------------

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "role-mcp-arquipuntos-${local.arquiebrio}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# -------------------------------------
# ECS: Custer, TaskDefinition & Service
# -------------------------------------

resource "aws_ecs_cluster" "main" {
  name = "ecs-custer-mcp-arquipuntos-${local.arquiebrio}"
}

resource "aws_ecs_task_definition" "mcp_task" {
  family                   = "ecs-task-mcp-arquipuntos-${local.arquiebrio}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name      = "tsk-definition-mcp-arquipuntos-${local.arquiebrio}"
      image     = "${local.image}:latest"
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
      environment = [
        { name = "DYNAMODB_TABLE", value = aws_dynamodb_table.mcp_table.name }
      ]
    }
  ])
}

resource "aws_ecs_service" "mcp_service" {
  name            = "ecs-service-mcp-arquipuntos-${local.arquiebrio}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.mcp_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.main.id]  #######
    security_groups  = [aws_security_group.alb_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "mcp-server"
    container_port   = 80
  }
  depends_on = [aws_lb_listener.alb_listener]
}