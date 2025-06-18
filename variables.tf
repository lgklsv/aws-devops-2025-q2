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

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be 'dev', 'staging', or 'prod'."
  }
}

variable "vpc_cidr" {
  description = "CIDR Block for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "The CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidr_blocks" {
  description = "The CIDR blocks for the private subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ssh_access_cidr" {
  description = "The CIDR block allowed for SSH access to the bastion host."
  type        = string
  default     = "0.0.0.0/0"
}
