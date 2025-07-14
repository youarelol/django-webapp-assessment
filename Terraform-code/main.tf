###################################### VPC ######################################
module "vpc" {
  source                  = "./modules/vpc"
  aws_vpc_cidr            = "10.0.0.0/16"
  aws_subnet_public_cidr  = "10.0.1.0/24"
  aws_subnet_public_cidr2 = "10.0.2.0/24"
  aws_subnet_private_cidr = "10.0.3.0/24"
  aws_subnet_private_cidr2= "10.0.4.0/24"
  availability_zone       = "ap-south-1a"
  availability_zone2      = "ap-south-1b"
}

####################################### VPN ######################################

module "vpn" {
  source         = "./modules/vpn"
  aws_vpc_id     = module.vpc.vpc_id
  aws_subnet_id  = module.vpc.aws_subnet_id
  aws_region     = "ap-south-1"
  aws_instance_type = "t3.small"
  key_name          = "OpenVPNAccessServer-key"
  admin_username    = "openvpn"
  admin_password    = "neuro12@#4"
  ami_id            = "ami-01614d815cf856337"
  project_name      = "Vpn"
  #depends_on        = [module.vpc]
}

################################### EKS Cluster ######################################

module "eks_cluster" {
  source = "./modules/eks"
  aws_region = "ap-south-1"
  aws_eks_cluster_name = "Assessment-cluster"
  aws_eks_cluster_version = "1.32" 
  aws_vpc_id = module.vpc.vpc_id
  aws_subnet_private_id = module.vpc.aws_subnet_private_id
  aws_subnet_private_id2 = module.vpc.aws_subnet_private_id2
  aws_subnet_id = module.vpc.aws_subnet_id
  aws_subnet_id2 = module.vpc.aws_subnet_id2
  aws_eks_node_group_name = "Assessment-node-group"
  aws_eks_node_group_min_size = 1
  aws_eks_node_group_max_size = 3
  aws_eks_node_group_desired_size = 1
  aws_eks_node_group_instance_type = "t3.medium"
  aws_eks_node_group_capacity_type = "ON_DEMAND"
  aws_eks_node_group_disk_size = 20
  aws_eks_node_group_volume_type = "gp3"
  aws_launch_template_name = "my-eks-launch-template"
  aws_launch_template_image_id = "ami-021a584b49225376d" # Example AMI ID, replace with your own
  #depends_on = [ module.vpc, module.vpn ]
}

# Local vars for readability
locals {
  eks_cluster_id = module.eks_cluster.eks_cluster_security_group_id
  vpn-sg_id = module.vpn.aws_security_group_id
}
# Allow EKS -> VPN on port 443
resource "aws_security_group_rule" "allow_eks_to_vpn" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "tcp"
  security_group_id        = local.vpn-sg_id
  source_security_group_id = local.eks_cluster_id
  description              = "Allow EKS to access VPN on port publicly"
}

################################## ECR Repository ######################################

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "assessment-repo"
}