variable "aws_region" {
  description = "AWS region to deploy the resources in"
  type        = string
}

variable "aws_instance_type" {
  description = "Access Server EC2 instance type"
  type        = string
}

variable "aws_vpc_id" {
  description = "ID of your existing Virtual Private Cloud (VPC)"
  type        = string
}

variable "aws_subnet_id" {
  description = "ID of your existing Subnet"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 KeyPair to enable SSH access to the instance"
  type        = string
}

variable "admin_username" {
  description = "The OpenVPN Access Server admin username"
  type        = string
}

variable "admin_password" {
  description = "The OpenVPN Access Server admin password"
  type        = string
}
variable "ami_id" {
  description = "OpenVPN AMI ID for the region"
  type        = string
}
variable "project_name" { 
  description = "Name of the project for resource tagging"
  type        = string

}

