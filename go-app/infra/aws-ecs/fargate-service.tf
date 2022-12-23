terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {}
}

variable "vpc_id" {
 type        = string
}

variable "aws_region" {
 type        = string
}

variable "aws_access_key" {
 type        = string
}

variable "aws_secret_key" {
 type        = string
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_ecs_task_definition" "my-web-app" {
  family = "my-web-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = "arn:aws:iam::268213776880:role/ecsTaskExecutionRole"
  container_definitions = jsonencode([
    {
      name      = "my-web-app"
      image     = "268213776880.dkr.ecr.us-east-1.amazonaws.com/ascii27:cdba04779a3b29c7ff244e8d61a3f98180070e18"
      cpu       = 1024
      memory    = 2048 
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}

resource "aws_security_group" "my-web-service-alb-security-group" {
  name        = "my-web-service-alb-security-group"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_lb_target_group" "my-web-service-lb-tg" {
  name     = "my-web-service-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  health_check {
    enabled = true
    path = "/health"
  }
}

resource "aws_lb" "my-web-service-lb" {
  name            = "my-web-service-lb"
  subnets         = ["subnet-e0adc8cd","subnet-208cd969"]
  security_groups = [aws_security_group.my-web-service-alb-security-group.id]
  depends_on = [aws_security_group.my-web-service-alb-security-group]
}

resource "aws_lb_listener" "my-web-service-lb-listener" {
  load_balancer_arn = aws_lb.my-web-service-lb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.my-web-service-lb-tg.id
    type             = "forward"
  }
  depends_on = [aws_lb_target_group.my-web-service-lb-tg, aws_lb.my-web-service-lb]
}

resource "aws_ecs_service" "my-web-app-service" {
  name            = "my-web-app-service"
  cluster         = "arn:aws:ecs:us-east-1:268213776880:cluster/bones"
  task_definition = aws_ecs_task_definition.my-web-app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.my-web-service-lb-tg.arn
    container_name   = "my-web-app"
    container_port   = 8080
  }

  network_configuration {
    subnets = ["subnet-e0adc8cd","subnet-208cd969"]
    security_groups = ["sg-03e58416d8c09ffa5"]
    assign_public_ip = true
  }

  depends_on = [aws_lb_listener.my-web-service-lb-listener]
}

