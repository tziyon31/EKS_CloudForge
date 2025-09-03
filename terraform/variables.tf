# =============================================================================
# TERRAFORM VARIABLES
# =============================================================================
# This file defines all the variables that can be customized
# Variables make our Terraform code reusable and flexible

# =============================================================================
# PROJECT CONFIGURATION VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project - used for resource naming and tagging"
  type        = string
  default     = "eks-cloudforge"

  # Validation to ensure the name follows AWS naming conventions
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod) - used for resource separation"
  type        = string
  default     = "dev"

  # Validation to ensure only valid environments are used
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the resources - used for tagging and cost tracking"
  type        = string
  default     = "devops-team"
}

# =============================================================================
# AWS CONFIGURATION VARIABLES
# =============================================================================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"

  # Using us-east-1 as it's cost-effective and has all required services
  # You can change this to your preferred region
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
  default     = ["us-east-1a"]

  # Using 1 AZ to avoid AWS limits (VPCs and EIPs)
  # Can scale to 2+ AZs later when limits are increased
}

variable "use_existing_vpc" {
  description = "Whether to use an existing VPC instead of creating a new one"
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "ID of existing VPC to use (if use_existing_vpc is true)"
  type        = string
  default     = "vpc-04bf56d087bf33531"  # The one without suffix
}

# =============================================================================
# VPC NETWORKING VARIABLES
# =============================================================================

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC (Virtual Private Cloud)"
  type        = string
  default     = "10.0.0.0/16"

  # This creates a VPC with 65,536 IP addresses
  # 10.0.0.0/16 is a private IP range that won't conflict with internet
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  # Each subnet gets 256 IP addresses (254 usable)
  # Public subnets can have internet access
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  # Private subnets are more secure - no direct internet access
  # EKS worker nodes will be in private subnets
}

# =============================================================================
# EKS CLUSTER VARIABLES
# =============================================================================

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "cloudforge-cluster"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"

  # Using a recent stable version
  # Check AWS EKS supported versions for latest
}

variable "eks_cluster_endpoint_public_access" {
  description = "Whether the EKS cluster endpoint is publicly accessible"
  type        = bool
  default     = true

  # Set to false for production for better security
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  # WARNING: 0.0.0.0/0 allows access from anywhere
  # In production, restrict this to your office/home IP
}

# =============================================================================
# EKS NODE GROUP VARIABLES
# =============================================================================

variable "eks_node_group_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.micro"]

  # t3.micro: 1 vCPU, 1 GB RAM - cost-effective for development
  # ~$8.47/month vs t3.medium ~$33.88/month (75% cost savings!)
  # Sufficient for lightweight Flask applications
  # Can auto-scale to larger instances if needed
}

variable "eks_node_group_desired_size" {
  description = "Desired number of worker nodes in each node group"
  type        = number
  default     = 2

  # Start with 2 nodes to minimize costs
  # Can scale up to 2+ nodes for high availability when needed
  # t3.micro at $8.47/month is very cost-effective
}

variable "eks_node_group_max_size" {
  description = "Maximum number of worker nodes in each node group"
  type        = number
  default     = 4

  # Allows auto-scaling up to 3 nodes if needed
  # Balances cost with performance requirements
  # 4 t3.micro instances = ~$32/month total
}

variable "eks_node_group_min_size" {
  description = "Minimum number of worker nodes in each node group"
  type        = number
  default     = 1

  # Minimum 1 node to keep the cluster running
  # Even during low traffic periods
}

# =============================================================================
# ECR REPOSITORY VARIABLES
# =============================================================================

variable "ecr_repository_name" {
  description = "Name of the ECR repository for Docker images"
  type        = string
  default     = "cloudforge-app"
}

variable "ecr_image_tag_mutability" {
  description = "The tag mutability setting for the ECR repository"
  type        = string
  default     = "MUTABLE"

  # MUTABLE: allows overwriting tags (good for development)
  # IMMUTABLE: prevents overwriting tags (better for production)
}

# =============================================================================
# S3 BUCKET VARIABLES (FOR TERRAFORM STATE)
# =============================================================================

variable "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for storing Terraform state"
  type        = string
  default     = "cloudforge-terraform-state"

  # This bucket stores the state of our infrastructure
  # Must be globally unique across all AWS accounts
}

variable "terraform_state_bucket_versioning" {
  description = "Whether to enable versioning on the Terraform state bucket"
  type        = bool
  default     = true

  # Versioning allows us to recover from accidental deletions
  # Essential for production environments
}

variable "terraform_state_bucket_encryption" {
  description = "Whether to enable encryption on the Terraform state bucket"
  type        = bool
  default     = true

  # Encryption protects sensitive data in the state file
  # Required for compliance and security
}
