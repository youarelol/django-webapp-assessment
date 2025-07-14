variable "aws_vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "aws_subnet_public_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}
variable "aws_subnet_public_cidr2" {
  description = "CIDR block for the public subnet"
  type        = string
}
variable "aws_subnet_private_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}
variable "aws_subnet_private_cidr2" {
  description = "CIDR block for the private subnet"
  type        = string
}
variable "availability_zone" {
  description = "Availability zone for the subnets"
  type        = string
}
variable "availability_zone2" {
  description = "Availability zone for the subnets"
  type        = string  
  
}