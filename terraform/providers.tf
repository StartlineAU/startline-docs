terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

data "aws_secretsmanager_secret" "bootstrap" {
  name = "startline/tf-bootstrap"
}

data "aws_secretsmanager_secret_version" "bootstrap" {
  secret_id = data.aws_secretsmanager_secret.bootstrap.id
}

locals {
  do_token = jsondecode(data.aws_secretsmanager_secret_version.bootstrap.secret_string).digitalocean_api_token
}

provider "digitalocean" {
  token = local.do_token
}
