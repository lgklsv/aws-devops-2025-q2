provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.s3_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Terraform State Bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = var.s3_bucket_name 
  versioning_configuration {
    status = "Enabled"
  }
}