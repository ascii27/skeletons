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

resource "aws_ecs_task_definition" "{{.APP_NAME}}" {
  family = "{{.APP_NAME}}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = "arn:aws:iam::268213776880:role/ecsTaskExecutionRole"
  container_definitions = jsonencode([
    {
      name      = "{{.APP_NAME}}"
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

resource "aws_security_group" "{{.SERVICE_NAME}}-alb-security-group" {
  name        = "{{.SERVICE_NAME}}-alb-security-group"
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



resource "aws_lb_target_group" "{{.SERVICE_NAME}}-lb-tg" {
  name     = "{{.SERVICE_NAME}}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  health_check {
    enabled = true
    path = "/health"
  }
}

resource "aws_lb" "{{.SERVICE_NAME}}-lb" {
  name            = "{{.SERVICE_NAME}}-lb"
  subnets         = ["subnet-e0adc8cd","subnet-208cd969"]
  security_groups = [aws_security_group.{{.SERVICE_NAME}}-alb-security-group.id]
  depends_on = [aws_security_group.{{.SERVICE_NAME}}-alb-security-group]
}

resource "aws_lb_listener" "{{.SERVICE_NAME}}-lb-listener" {
  load_balancer_arn = aws_lb.{{.SERVICE_NAME}}-lb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.{{.SERVICE_NAME}}-lb-tg.id
    type             = "forward"
  }
  depends_on = [aws_lb_target_group.{{.SERVICE_NAME}}-lb-tg, aws_lb.{{.SERVICE_NAME}}-lb]
}

resource "aws_ecs_service" "{{.SERVICE_NAME}}" {
  name            = "{{.SERVICE_NAME}}"
  cluster         = "arn:aws:ecs:us-east-1:268213776880:cluster/bones"
  task_definition = aws_ecs_task_definition.{{.APP_NAME}}.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.{{.SERVICE_NAME}}-lb-tg.arn
    container_name   = "{{.APP_NAME}}" 
    container_port   = 8080
  }

  network_configuration {
    subnets = ["subnet-e0adc8cd","subnet-208cd969"]
    security_groups = ["sg-03e58416d8c09ffa5"]
    assign_public_ip = true
  }

  depends_on = [aws_lb_listener.{{.SERVICE_NAME}}-lb-listener]
}

