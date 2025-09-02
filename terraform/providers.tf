# =============================================================================
# TERRAFORM PROVIDER CONFIGURATION
# =============================================================================
# This file configures the cloud providers we'll use for our infrastructure
# We're using AWS as our primary cloud provider

# Configure the AWS Provider
# This tells Terraform which cloud provider to use and how to authenticate
terraform {
  # Configure the required providers and their versions
  required_providers {
    # AWS Provider - for creating AWS resources (EC2, VPC, EKS, etc.)
    aws = {
      source  = "hashicorp/aws" # Official AWS provider from HashiCorp
      version = "~> 5.0"        # Use version 5.x (latest stable)
    }

    # Kubernetes Provider - for managing Kubernetes resources
    kubernetes = {
      source  = "hashicorp/kubernetes" # Official Kubernetes provider
      version = "~> 2.0"               # Use version 2.x
    }

    # Helm Provider - for deploying Helm charts
    helm = {
      source  = "hashicorp/helm" # Official Helm provider
      version = "~> 2.0"         # Use version 2.x
    }
  }
}

# Configure the AWS Provider
# This section defines how Terraform connects to AWS
provider "aws" {
  # AWS Region where we'll create our resources
  # Using us-east-1 (N. Virginia) as it's cost-effective and has all services
  region = var.aws_region

  # Default tags that will be applied to all resources
  # This helps with cost tracking and resource management
  default_tags {
    tags = {
      Project     = var.project_name # Name of our project
      Environment = var.environment  # Environment (dev/staging/prod)
      ManagedBy   = "Terraform"      # Indicates this is managed by Terraform
      Owner       = var.owner        # Who owns these resources
    }
  }
}
