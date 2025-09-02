# =============================================================================
# TERRAFORM OUTPUTS
# =============================================================================
# This file defines what information to display after Terraform runs
# These outputs provide important values for the next steps in our pipeline

# =============================================================================
# EKS CLUSTER OUTPUTS
# =============================================================================

# EKS cluster name
# This is used by kubectl and other tools to identify the cluster
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

# EKS cluster endpoint
# This is the URL where you can access the Kubernetes API
output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

# EKS cluster version
# Shows which Kubernetes version is running
output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

# EKS cluster ARN
# The Amazon Resource Name for the cluster
output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

# EKS cluster certificate authority data
# This is needed for kubectl to authenticate with the cluster
output "eks_cluster_certificate_authority_data" {
  description = "Certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

# =============================================================================
# ECR REPOSITORY OUTPUTS
# =============================================================================

# ECR repository URL
# This is where Docker images will be pushed and pulled from
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

# ECR repository name
# The name of the repository
output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.app.name
}

# ECR repository ARN
# The Amazon Resource Name for the repository
output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.app.arn
}

# =============================================================================
# VPC AND NETWORKING OUTPUTS
# =============================================================================

# VPC ID
# The ID of the VPC that was created
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# VPC CIDR block
# The IP range for the VPC
output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Public subnet IDs
# List of public subnet IDs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

# Private subnet IDs
# List of private subnet IDs (where EKS nodes are located)
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# =============================================================================
# IAM ROLE OUTPUTS
# =============================================================================

# EKS cluster IAM role ARN
# The ARN of the IAM role used by the EKS cluster
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

# EKS node group IAM role ARN
# The ARN of the IAM role used by EKS worker nodes
output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group.arn
}

# =============================================================================
# S3 BUCKET OUTPUTS
# =============================================================================

# Terraform state bucket name
# The name of the S3 bucket storing Terraform state
output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

# Terraform state bucket ARN
# The ARN of the S3 bucket
output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

# =============================================================================
# SECURITY GROUP OUTPUTS
# =============================================================================

# EKS cluster security group ID
# The ID of the security group for the EKS cluster
output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_security_group.eks_cluster.id
}

# EKS worker security group ID
# The ID of the security group for EKS worker nodes
output "eks_worker_security_group_id" {
  description = "ID of the EKS worker security group"
  value       = aws_security_group.eks_worker.id
}

# =============================================================================
# USEFUL COMMANDS OUTPUTS
# =============================================================================

# kubectl configuration command
# This command configures kubectl to connect to our EKS cluster
output "kubectl_config_command" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

# Docker login command for ECR
# This command logs Docker into ECR so you can push/pull images
output "docker_login_command" {
  description = "Command to log Docker into ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}"
}

# Docker tag command example
# Example of how to tag a Docker image for ECR
output "docker_tag_command_example" {
  description = "Example command to tag a Docker image for ECR"
  value       = "docker tag your-app:latest ${aws_ecr_repository.app.repository_url}:latest"
}

# Docker push command example
# Example of how to push a Docker image to ECR
output "docker_push_command_example" {
  description = "Example command to push a Docker image to ECR"
  value       = "docker push ${aws_ecr_repository.app.repository_url}:latest"
}

# =============================================================================
# COST ESTIMATION OUTPUTS
# =============================================================================

# Estimated monthly cost information
# This provides a rough estimate of the infrastructure costs
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    "EKS Cluster"     = "~$73.00/month (EKS control plane)"
    "EC2 Instances"   = "~$16.94/month (2x t3.micro nodes)"
    "NAT Gateways"    = "~$45.00/month (2x NAT Gateways)"
    "EIP Addresses"   = "~$3.50/month (2x Elastic IPs)"
    "S3 Storage"      = "~$0.50/month (Terraform state)"
    "ECR Storage"     = "~$0.50/month (Docker images)"
    "Total Estimated" = "~$139.44/month"
  }
}

# Cost optimization notes
output "cost_optimization_notes" {
  description = "Notes for cost optimization"
  value = [
    "NAT Gateways are the biggest cost (~$45/month each)",
    "Consider using NAT Instances for development to save costs",
    "EKS control plane costs ~$73/month regardless of node count",
    "t3.micro instances are very cost-effective at ~$8.47/month each",
    "Auto-scaling will only scale up when needed, reducing costs"
  ]
}
