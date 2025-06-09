terraform {
  backend "s3" {
    bucket = "aws-devops-course-terraform-state-bucket"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-1"
  }
}
