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

output "internet_gateway_id" {
  value = aws_internet_gateway.gw.id
}

# output "webapp_public_ip" {
#   description = "Public IP of the WebApp EC2 instance"
#   value       = aws_instance.eb_app.public_ip
# }

output "db_address" {
  value = aws_db_instance.rds_instance.address
}

output "webapp_url" {
  value = aws_lb.web_alb.dns_name
}