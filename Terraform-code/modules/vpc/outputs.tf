output "vpc_id" {
  description = "Name of the VPC"
  value       = aws_vpc.main.id 
}
output "aws_subnet_id" {
  description = "Name of the public subnet"
  value       = aws_subnet.public1.id
}
output "aws_subnet_private_id" {
  description = "Name of the private subnet"
  value       = aws_subnet.private1.id
}
output "aws_subnet_id2" {
  description = "Name of the public subnet"
  value       = aws_subnet.public2.id
}
output "aws_subnet_private_id2" {
  description = "Name of the private subnet"
  value       = aws_subnet.private2.id
  
}