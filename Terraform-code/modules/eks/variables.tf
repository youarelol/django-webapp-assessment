variable "aws_region" {
  description = "The AWS region to deploy the EKS cluster."
  type        = string
  
}
variable "aws_vpc_id" {
  description = "The ID of the VPC where the EKS cluster will be deployed."
  type        = string  
}
variable "aws_eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}
variable "aws_eks_cluster_version" {
  description = "The version of the EKS cluster."
  type        = string
  default     = "1.21"
  
}
variable "aws_subnet_id" {
    description = "The ID of the private subnet for the EKS cluster."
    type        = string
}
variable "aws_subnet_id2" {
    description = "The ID of the second private subnet for the EKS cluster."
    type        = string
}
variable "aws_subnet_private_id" {
  description = "The ID of the private subnet for the EKS cluster."
  type        = string
}
variable "aws_subnet_private_id2" {
  description = "The ID of the second private subnet for the EKS cluster."
  type        = string  
}
variable "aws_eks_node_group_name" {
  description = "The name of the EKS node group."
  type        = string
}
variable "aws_eks_node_group_min_size" {
  description = "The minimum size of the EKS node group."
  type        = number
}
variable "aws_eks_node_group_max_size" {
  description = "The maximum size of the EKS node group."
  type        = number
}
variable "aws_eks_node_group_desired_size" {
  description = "The desired size of the EKS node group."
  type        = number
}
variable "aws_eks_node_group_instance_type" {
  description = "The instance type for the EKS node group."
  type        = string
}
variable "aws_eks_node_group_capacity_type" {
  description = "The capacity type for the EKS node group."
  type        = string
}
variable "aws_eks_node_group_disk_size" {
  description = "The disk size for the EKS node group."
    type        = number
}
variable "aws_eks_node_group_volume_type" {
  description = "The volume type for the EKS node group."
  type        = string
  
}
variable "aws_launch_template_name" {
  description = "The name of the launch template for the EKS node group."
  type        = string
}
variable "aws_launch_template_image_id" {
  description = "The AMI ID for the launch template."
  type        = string
}
variable "aws_key_name" {
  description = "The name of the key pair to use for SSH access to the EKS nodes."
  type        = string
  default     = null
}

