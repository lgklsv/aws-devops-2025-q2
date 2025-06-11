variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "The name for the S3 bucket."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be 'dev', 'staging', or 'prod'."
  }
}