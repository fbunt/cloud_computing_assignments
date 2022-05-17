terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"

  # Tags that are applied to all components
  # These can help distinguish between production and debug runs or indicate
  # who is running infrastructure on a team.
  default_tags {
    tags = {
      Environment = var.environment
      Owner       = var.owner
    }
  }
}


# Default VPC
# data resources allow you to get information about infrastructure components
# that already exist. These data objects get the default VPC and subnets that
# AWS creates for all accounts.
data "aws_vpc" "default" {
  default = true
}
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}


# ------------ You should not have to change anything above here ------------


# --- Security Group ---


# --- S3 Bucket ---


# --- EC2 Instance Config ---


# --- Load Balancing ---


# --- Auto Scaling ---
