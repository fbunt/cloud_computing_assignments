# Partially based on https://adamtheautomator.com/terraform-aws/#What_is_the_AWS_Provider
# Declaring the Provider Requirements
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configuring the AWS Provider (aws) with region set to 'us-west-2'
provider "aws" {
  region = var.region
}

# Granting the Bucket Access
resource "aws_s3_bucket_public_access_block" "publicaccess" {
  bucket = aws_s3_bucket.umcs-bucket.id
  block_public_acls = false
  block_public_policy = false
}

# Creating the encryption key which will encrypt the bucket objects
resource "aws_kms_key" "mykey" {
  deletion_window_in_days = "20"
}

# Creating the bucket named terraformdemobucket
resource "aws_s3_bucket" umcs-bucket {
  bucket        = "umcs-bucket"
  force_destroy = false
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  # Keeping multiple versions of an object in the same bucket
  versioning {
    enabled = true
  }
}
