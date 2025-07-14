# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "eks-cluster-role"
  }
}

# Attach AmazonEKSClusterPolicy to EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  
}

resource "aws_security_group" "eks_cluster" {
  name_prefix = "eks-cluster-sg-"
  vpc_id      = var.aws_vpc_id
  description = "Security group for EKS cluster control plane"

  # Allow inbound HTTPS from worker nodes and external clients
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to specific CIDRs (e.g., your VPC or office IP) for production
    description = "Allow Kubernetes API server access"
  }
  # Allow inbound traffic from VPN security group (for admin or internal access)
#  ingress {
#    from_port       = 443
#    to_port         = 443
#    protocol        = "tcp"
#    security_groups = var.aws_vpn_security_group_ids
#    description     = "Allow Kubernetes API access from VPN"
#  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }


  tags = {
    Name = "eks-cluster-sg"
  }
}
# EKS Cluster   
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.aws_eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.aws_eks_cluster_version
    tags = {
        Name = "eks-cluster"
    }

  vpc_config {
    subnet_ids = [
      var.aws_subnet_private_id,
      var.aws_subnet_private_id2 
    ]
    security_group_ids = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true  # Enable private API server access
    endpoint_public_access  = false # Disable public API server access
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
  # EKS Add-ons

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# Optionally, enable Amazon EBS CSI Driver if you use EBS volumes
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# Optionally, enable Amazon EFS CSI Driver if you use EFS volumes
resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "aws-efs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# Add this before the aws_eks_node_group resource
resource "null_resource" "wait_for_cluster" {
  depends_on = [aws_eks_cluster.eks_cluster]

  provisioner "local-exec" {
    command = <<EOT
      for /l %i in (1,1,30) do (
        for /f "tokens=*" %%a in ('aws eks describe-cluster --name my-eks-cluster --region ap-south-1 --query "cluster.status" --output text') do set CLUSTER_STATUS=%%a
        if "!CLUSTER_STATUS!"=="ACTIVE" (
          echo Cluster is ACTIVE
          exit /b 0
        )
        echo Waiting for cluster to be ACTIVE... (%i/30)
        timeout /t 30 /nobreak
      )
      echo Cluster did not become ACTIVE after 15 minutes
      exit /b 1
    EOT
    interpreter = ["cmd", "/c"]
  }
}

# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "eks-node-role"
  }
}

# Attach required policies to EKS Node Role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "eks_AmazonEBSCSIDriverPolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
resource "aws_iam_role_policy_attachment" "eks_AmazonEC2ContainerRegistryPowerUser" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# aws node group 

resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = var.aws_eks_cluster_name
  node_group_name = var.aws_eks_node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    var.aws_subnet_private_id,
    var.aws_subnet_private_id2
  ]

  capacity_type  = var.aws_eks_node_group_capacity_type
  instance_types = [var.aws_eks_node_group_instance_type]

  scaling_config {
    desired_size = var.aws_eks_node_group_desired_size
    max_size     = var.aws_eks_node_group_max_size
    min_size     = var.aws_eks_node_group_min_size 
    }

  update_config {
    max_unavailable = 1
  }

  labels = {
    node = "kubenode02"
  }


  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.eks_AmazonEBSCSIDriverPolicy,
    aws_iam_role_policy_attachment.eks_AmazonEC2ContainerRegistryPowerUser,
    null_resource.wait_for_cluster,
    aws_launch_template.eks-with-disks
  ]
# launch template if required
}
resource "aws_launch_template" "eks-with-disks" {
    name_prefix   = var.aws_launch_template_name
    image_id      = var.aws_launch_template_image_id # Amazon Linux 2 AMI
    instance_type = var.aws_eks_node_group_instance_type
    key_name      = var.aws_key_name # Optional: specify your key pair for SSH access
    
    vpc_security_group_ids = [aws_security_group.eks_nodes.id]

    lifecycle {
        create_before_destroy = true
    }
    
    block_device_mappings {
        device_name = "/dev/xvda"
    
        ebs {
        volume_size = var.aws_eks_node_group_disk_size
        volume_type = var.aws_eks_node_group_volume_type
        }
    }
}
resource "aws_security_group" "eks_nodes" {
  name_prefix = "eks-nodes-sg-"
  vpc_id      = var.aws_vpc_id
  description = "Security group for EKS worker nodes"

  # Allow inbound traffic from the EKS control plane (port 443 for API server)
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "Allow EKS control plane to communicate with nodes"
  }

  # Allow inter-node communication (e.g., for Kubernetes networking)
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "Allow inter-node communication"
  }

  # Allow SSH for debugging (optional, restrict CIDR for production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP range for security
    description = "Allow SSH access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "eks-nodes-sg"
  }
}

