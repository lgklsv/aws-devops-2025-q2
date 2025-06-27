resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH traffic to bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from specified CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_access_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion SG"
  }
}

resource "aws_security_group" "internal" {
  name        = "internal-sg"
  description = "Allow traffic from within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow all traffic from the VPC CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Internal SG"
  }
}