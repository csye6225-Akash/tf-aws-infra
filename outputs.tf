

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "first_public_subnet" {
  value = aws_subnet.public_subnets[0].id
  description = "ID of the first public subnet"
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "public_route_table_id" {
  value = aws_route_table.public_route_table.id
}

output "private_route_table_id" {
  value = aws_route_table.private_route_table.id
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.web_sg.id
}

output "security_group_name" {
  description = "The name of the security group"
  value       = aws_security_group.web_sg.name
}

