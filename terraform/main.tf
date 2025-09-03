# =============================================================================
# MAIN TERRAFORM INFRASTRUCTURE
# =============================================================================
# This file creates all the AWS resources needed for our EKS deployment
# We'll create resources in the correct order (dependencies first)

# =============================================================================
# DATA SOURCES (Get existing AWS information)
# =============================================================================

# Get the current AWS account ID
# This is used for creating IAM roles and other resources that need the account ID
data "aws_caller_identity" "current" {
  # No configuration needed - automatically gets current user/role info
}

# Get the current AWS region
# This ensures we're using the correct region for all resources
data "aws_region" "current" {
  # No configuration needed - automatically gets current region
}

# Get the default VPC (we'll create our own, but this is useful for reference)
data "aws_vpc" "default" {
  default = true
}

# =============================================================================
# RANDOM IDENTIFIERS FOR UNIQUE RESOURCE NAMES
# =============================================================================
# Generate unique identifiers to avoid naming conflicts
# This ensures our resources have globally unique names

resource "random_id" "unique_suffix" {
  byte_length = 4
}

# =============================================================================
# S3 BUCKET FOR TERRAFORM STATE
# =============================================================================
# This bucket stores the Terraform state file
# State file contains information about all created resources
# Storing it in S3 allows team collaboration and state backup

resource "aws_s3_bucket" "terraform_state" {
  # Bucket name must be globally unique across all AWS accounts
  bucket = "${var.terraform_state_bucket_name}-${random_id.unique_suffix.hex}"

  # Tags for cost tracking and resource management
  tags = {
    Name        = "Terraform State Bucket"
    Purpose     = "Store Terraform state files"
    Environment = var.environment
  }
}

# Enable versioning on the S3 bucket
# This allows us to recover from accidental deletions or corruption
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled" # Enable versioning
  }
}

# Enable server-side encryption for the S3 bucket
# This encrypts all data stored in the bucket (including state files)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Use AES256 encryption
    }
  }
}

# Block public access to the S3 bucket
# State files contain sensitive information and should never be public
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# VPC AND NETWORKING
# =============================================================================
# Create a custom VPC with public and private subnets
# This provides network isolation and security

# Use existing VPC or create new one
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  id    = var.existing_vpc_id
}

# Create the main VPC (only if not using existing)
resource "aws_vpc" "main" {
  count = var.use_existing_vpc ? 0 : 1
  
  # CIDR block defines the IP range for the VPC
  cidr_block = var.vpc_cidr_block

  # Enable DNS hostnames for the VPC
  # This allows instances to have DNS names
  enable_dns_hostnames = true

  # Enable DNS resolution for the VPC
  # This allows instances to resolve DNS names
  enable_dns_support = true

  tags = {
    Name = "${var.project_name}-vpc-${random_id.unique_suffix.hex}"
  }
}

# Local value for VPC ID
locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.main[0].id
}

# Create an Internet Gateway
# This allows instances in public subnets to access the internet
resource "aws_internet_gateway" "main" {
  # Attach to our VPC
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.project_name}-igw-${random_id.unique_suffix.hex}"
  }
}

# Create public subnets (one per availability zone)
# Public subnets can have internet access via the Internet Gateway
resource "aws_subnet" "public" {
  # Create one subnet for each availability zone
  count = length(var.availability_zones)

  # VPC this subnet belongs to
  vpc_id = local.vpc_id

  # CIDR block for this subnet
  cidr_block = var.public_subnet_cidrs[count.index]

  # Availability zone for this subnet
  availability_zone = var.availability_zones[count.index]

  # Enable auto-assign public IP addresses
  # This allows instances to get public IPs automatically
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}-${random_id.unique_suffix.hex}"
    # Tag for Kubernetes to identify public subnets
    "kubernetes.io/role/elb" = "1"
  }
}

# Create private subnets (one per availability zone)
# Private subnets cannot access internet directly (more secure)
resource "aws_subnet" "private" {
  # Create one subnet for each availability zone
  count = length(var.availability_zones)

  # VPC this subnet belongs to
  vpc_id = local.vpc_id

  # CIDR block for this subnet
  cidr_block = var.private_subnet_cidrs[count.index]

  # Availability zone for this subnet
  availability_zone = var.availability_zones[count.index]

  # Disable auto-assign public IP addresses
  # Private subnets should not have public IPs
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}-${random_id.unique_suffix.hex}"
    # Tag for Kubernetes to identify private subnets
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Create a route table for public subnets
# This defines how traffic flows in public subnets
resource "aws_route_table" "public" {
  # VPC this route table belongs to
  vpc_id = local.vpc_id

  # Route all internet traffic (0.0.0.0/0) through the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${random_id.unique_suffix.hex}"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  # Create one association for each public subnet
  count = length(var.availability_zones)

  # Subnet to associate
  subnet_id = aws_subnet.public[count.index].id

  # Route table to associate with
  route_table_id = aws_route_table.public.id
}

# Create Elastic IP addresses for NAT Gateways
# NAT Gateways allow private subnet instances to access internet
resource "aws_eip" "nat" {
  # Create one EIP for each availability zone
  count = length(var.availability_zones)

  # Domain must be vpc for use with NAT Gateway
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}-${random_id.unique_suffix.hex}"
  }
}

# Create NAT Gateways (one per availability zone)
# NAT Gateways allow private subnet instances to access internet
resource "aws_nat_gateway" "main" {
  # Create one NAT Gateway for each availability zone
  count = length(var.availability_zones)

  # Allocate Elastic IP for this NAT Gateway
  allocation_id = aws_eip.nat[count.index].id

  # Place NAT Gateway in public subnet
  subnet_id = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gateway-${count.index + 1}-${random_id.unique_suffix.hex}"
  }

  # Depend on Internet Gateway to ensure it exists first
  depends_on = [aws_internet_gateway.main]
}

# Create route tables for private subnets
# This defines how traffic flows in private subnets
resource "aws_route_table" "private" {
  # Create one route table for each availability zone
  count = length(var.availability_zones)

  # VPC this route table belongs to
  vpc_id = local.vpc_id

  # Route all internet traffic (0.0.0.0/0) through the NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}-${random_id.unique_suffix.hex}"
  }
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  # Create one association for each private subnet
  count = length(var.availability_zones)

  # Subnet to associate
  subnet_id = aws_subnet.private[count.index].id

  # Route table to associate with
  route_table_id = aws_route_table.private[count.index].id
}

# =============================================================================
# IAM ROLES AND POLICIES
# =============================================================================
# Create IAM roles and policies for EKS cluster and node groups
# These define what permissions our resources have

# Create IAM role for EKS cluster
# This role allows EKS to manage cluster resources
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role-${random_id.unique_suffix.hex}"

  # Trust policy allows EKS to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the Amazon EKS Cluster Policy to the EKS cluster role
# This policy provides permissions for EKS to manage cluster resources
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  # Role to attach policy to
  role = aws_iam_role.eks_cluster.name

  # Policy to attach
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create IAM role for EKS node groups
# This role allows EKS worker nodes to access AWS services
resource "aws_iam_role" "eks_node_group" {
  name = "${var.project_name}-eks-node-group-role-${random_id.unique_suffix.hex}"

  # Trust policy allows EKS node groups to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the Amazon EKS Worker Node Policy to the node group role
# This policy provides permissions for worker nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  # Role to attach policy to
  role = aws_iam_role.eks_node_group.name

  # Policy to attach
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach the Amazon EKS CNI Policy to the node group role
# This policy provides permissions for networking
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  # Role to attach policy to
  role = aws_iam_role.eks_node_group.name

  # Policy to attach
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach the Amazon EC2 Container Registry Read-Only Policy to the node group role
# This policy allows worker nodes to pull images from ECR
resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
  # Role to attach policy to
  role = aws_iam_role.eks_node_group.name

  # Policy to attach
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# =============================================================================
# EKS CLUSTER
# =============================================================================
# Create the EKS cluster
# This is the main Kubernetes cluster where our applications will run

resource "aws_eks_cluster" "main" {
  # Name of the EKS cluster
  name = "${var.eks_cluster_name}-${random_id.unique_suffix.hex}"

  # Kubernetes version for the cluster
  version = var.eks_cluster_version

  # IAM role for the EKS cluster
  role_arn = aws_iam_role.eks_cluster.arn

  # VPC configuration for the cluster
  vpc_config {
    # Subnet IDs where the cluster will be created
    # We'll use private subnets for the cluster control plane
    subnet_ids = aws_subnet.private[*].id

    # Whether the cluster endpoint is publicly accessible
    endpoint_public_access = var.eks_cluster_endpoint_public_access

    # CIDR blocks that can access the cluster endpoint
    public_access_cidrs = var.eks_cluster_endpoint_public_access_cidrs
  }

  # Ensure IAM role is created before the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "${var.eks_cluster_name}-${random_id.unique_suffix.hex}"
  }
}

# =============================================================================
# EKS NODE GROUPS
# =============================================================================
# Create EKS node groups (worker nodes)
# These are the EC2 instances that run your Kubernetes pods

resource "aws_eks_node_group" "main" {
  # Name of the node group
  node_group_name = "${var.project_name}-node-group-${random_id.unique_suffix.hex}"

  # EKS cluster this node group belongs to
  cluster_name = aws_eks_cluster.main.name

  # IAM role for the node group
  node_role_arn = aws_iam_role.eks_node_group.arn

  # Subnet IDs where worker nodes will be created
  # We'll use private subnets for security
  subnet_ids = aws_subnet.private[*].id

  # Instance types for worker nodes
  instance_types = var.eks_node_group_instance_types

  # Scaling configuration
  scaling_config {
    # Desired number of worker nodes
    desired_size = var.eks_node_group_desired_size

    # Maximum number of worker nodes
    max_size = var.eks_node_group_max_size

    # Minimum number of worker nodes
    min_size = var.eks_node_group_min_size
  }

  # Update configuration
  update_config {
    # Maximum number of nodes that can be unavailable during updates
    max_unavailable = 1
  }

  # Ensure IAM roles are created before the node group
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only_policy
  ]

  tags = {
    Name = "${var.project_name}-node-group-${random_id.unique_suffix.hex}"
  }
}

# =============================================================================
# ECR REPOSITORY
# =============================================================================
# Create ECR repository for storing Docker images
# This is where our Flask application images will be stored

resource "aws_ecr_repository" "app" {
  # Name of the ECR repository
  name = "${var.ecr_repository_name}-${random_id.unique_suffix.hex}"

  # Image tag mutability setting
  image_tag_mutability = var.ecr_image_tag_mutability

  # Force delete the repository when destroying
  # This allows Terraform to clean up the repository
  force_delete = true

  tags = {
    Name = "${var.ecr_repository_name}-${random_id.unique_suffix.hex}"
  }
}

# Configure ECR repository lifecycle policy
# This automatically deletes old images to save storage costs
resource "aws_ecr_lifecycle_policy" "app" {
  # ECR repository this policy applies to
  repository = aws_ecr_repository.app.name

  # Lifecycle policy configuration
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================
# Create security groups for network security
# These control what traffic can reach our resources

# Security group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  # Name of the security group
  name_prefix = "${var.project_name}-eks-cluster-${random_id.unique_suffix.hex}-"

  # VPC this security group belongs to
  vpc_id = local.vpc_id

  # Description of the security group
  description = "Security group for EKS cluster"

  # Inbound rules (what traffic can come in)
  ingress {
    # Allow all traffic from within the VPC
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow all traffic from within VPC"
  }

  # Outbound rules (what traffic can go out)
  egress {
    # Allow all outbound traffic
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-eks-cluster-sg-${random_id.unique_suffix.hex}"
  }
}

# Security group for EKS worker nodes
resource "aws_security_group" "eks_worker" {
  # Name of the security group
  name_prefix = "${var.project_name}-eks-worker-${random_id.unique_suffix.hex}-"

  # VPC this security group belongs to
  vpc_id = local.vpc_id

  # Description of the security group
  description = "Security group for EKS worker nodes"

  # Inbound rules (what traffic can come in)
  ingress {
    # Allow all traffic from within the VPC
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow all traffic from within VPC"
  }

  # Outbound rules (what traffic can go out)
  egress {
    # Allow all outbound traffic
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-eks-worker-sg-${random_id.unique_suffix.hex}"
  }
}
