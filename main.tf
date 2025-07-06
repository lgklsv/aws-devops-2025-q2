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

resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.k3s_nodes.id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    curl -sfL https://get.k3s.io | sh -
  EOF

  tags = {
    Name = "k3s-master"
  }
}

resource "aws_instance" "k3s_worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private[1].id
  vpc_security_group_ids = [aws_security_group.k3s_nodes.id]
  key_name               = var.key_name

  depends_on = [aws_instance.k3s_master]

  user_data = <<-EOF
    #!/bin/bash
    # Worker join script will need to be run manually after master is ready
  EOF

  tags = {
    Name = "k3s-worker"
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

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
