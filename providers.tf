terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.37.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.1.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_region" "current" {}
data "aws_caller_identity" "self" {}