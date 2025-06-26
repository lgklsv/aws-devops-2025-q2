provider "aws" {
  region = var.aws_region
}

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = var.s3_bucket_name

#   lifecycle {
#     prevent_destroy = true
#   }

#   tags = {
#     Name        = "Terraform State Bucket"
#     Environment = var.environment
#   }
# }

# resource "aws_s3_bucket_versioning" "terraform_state" {
#   bucket = var.s3_bucket_name
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name

  tags = {
    Name = "Bastion Host"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
