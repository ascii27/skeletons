terraform {
  required_providers {
    circleci = {
      source  = "severgroup-tt/circleci"
      version = "~>0.6.5"
    }
  }
}

provider "circleci" {
  token   = "0ff13edf53c1a86bef4250342b1c12979436d058"
}

resource "circleci_project" "my-basic-web-service" {
  vcs_type = "github"
  username = "ascii27"
  name     = "my-basic-web-service"
}
