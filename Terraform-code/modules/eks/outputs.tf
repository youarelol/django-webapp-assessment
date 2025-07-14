    output "aws_iam_role_node_arn" {
    description = "ARN of the IAM role for EKS worker nodes"
    value       = aws_iam_role.eks_node_role.arn
    }
    output "aws_eks_cluster_name" {
    description = "Name of the EKS cluster"
    value       = aws_eks_cluster.eks_cluster.name
    }
    output "aws_eks_cluster_endpoint" {
    description = "Endpoint of the EKS cluster"
    value       = aws_eks_cluster.eks_cluster.endpoint
    }
    output "eks_cluster_security_group_id" {
    description = "Security group ID for the EKS cluster"
    value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}
