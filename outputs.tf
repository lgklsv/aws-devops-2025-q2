output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the created public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the created private subnets."
  value       = aws_subnet.private[*].id
}

output "bastion_security_group_id" {
  description = "The ID of the bastion host security group."
  value       = aws_security_group.bastion.id
}

output "internal_security_group_id" {
  description = "The ID of the internal security group."
  value       = aws_security_group.internal.id
}

output "nat_gateway_public_ip" {
  description = "The public IP of the NAT Gateway."
  value       = aws_eip.nat.public_ip
}
