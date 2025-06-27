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

resource "aws_security_group" "k3s_nodes" {
  name        = "k3s-nodes-sg"
  description = "Allow SSH and k3s API access to k3s nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "k3s API from Bastion"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description = "k3s API from local IP"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k3s Nodes SG"
  }
}

resource "aws_security_group_rule" "k3s_nodes_ingress_api_self" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s_nodes.id
  source_security_group_id = aws_security_group.k3s_nodes.id
  description              = "k3s API from k3s nodes"
}