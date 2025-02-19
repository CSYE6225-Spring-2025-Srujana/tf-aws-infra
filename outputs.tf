output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of created public subnets"
  value       = aws_subnet.subnets_public[*].id
}

output "private_subnet_ids" {
  description = "IDs of created private subnets"
  value       = aws_subnet.subnets_private[*].id
}