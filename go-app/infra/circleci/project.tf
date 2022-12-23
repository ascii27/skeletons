terraform {
  required_providers {
    circleci = {
      source  = "severgroup-tt/circleci"
      version = "~>0.6.5"
    }
  },
  backend "s3" {
    bucket = "bones-server"
    key    = "my-web-server/infra/circleci"
    region = "us-east-1"
  }
}

variable "circleci_token" {
 type        = string
}

variable "project_name" {
 type        = string
}

variable "github_user" {
 type        = string
}

provider "circleci" {
  token   = var.circleci_token 
}

resource "circleci_project" "app_project" {
  vcs_type = "github"
  username = var.github_user
  name     = var.project_name
}
