# Terraform Infrastructure Deployment Guide

## Overview
This guide walks you through deploying the AWS infrastructure for the EKS CloudForge project using Terraform. The infrastructure includes VPC, EKS cluster, ECR repository, and all necessary networking components.

## Prerequisites

### Required Tools
- **Terraform** (version >= 1.0)
- **AWS CLI** (configured with appropriate credentials)
- **kubectl** (for interacting with the EKS cluster)
- **Docker** (for building and pushing images)

### AWS Permissions
Your AWS user/role needs the following permissions:
- `AmazonEC2FullAccess`
- `AmazonEKSFullAccess`
- `AmazonECRFullAccess`
- `AmazonS3FullAccess`
- `IAMFullAccess`
- `AmazonVPCFullAccess`

## Step-by-Step Deployment

### Step 1: Verify Prerequisites

```bash
# Check Terraform version
terraform version

# Check AWS CLI configuration
aws sts get-caller-identity

# Check if you have the required tools
which kubectl
which docker
```

### Step 2: Navigate to Terraform Directory

```bash
cd terraform
```

### Step 3: Initialize Terraform

```bash
# Initialize Terraform and download required providers
terraform init
```

**What this does:**
- Downloads the AWS provider and other required plugins
- Sets up the working directory
- Prepares Terraform to manage your infrastructure

### Step 4: Review the Plan

```bash
# See what resources Terraform will create
terraform plan
```

**What to look for:**
- **Resource count**: Should show ~20+ resources being created
- **Cost implications**: Review the estimated costs
- **Resource names**: Ensure they match your expectations
- **No errors**: All resources should plan successfully

### Step 5: Deploy the Infrastructure

```bash
# Apply the Terraform configuration
terraform apply
```

**What happens during deployment:**
1. **S3 Bucket**: Created first (for Terraform state)
2. **VPC & Networking**: VPC, subnets, route tables, NAT gateways
3. **IAM Roles**: EKS cluster and node group roles
4. **EKS Cluster**: Kubernetes control plane
5. **EKS Node Groups**: Worker nodes (EC2 instances)
6. **ECR Repository**: Container registry
7. **Security Groups**: Network security rules

**Expected duration:** 15-20 minutes

### Step 6: Verify the Deployment

```bash
# Check that all resources were created successfully
terraform show

# View the outputs (important information)
terraform output
```

## Important Outputs

After successful deployment, Terraform will output important information:

### EKS Cluster Information
- **Cluster Name**: Used by kubectl and other tools
- **Cluster Endpoint**: Kubernetes API server URL
- **Certificate Authority**: For kubectl authentication

### ECR Repository Information
- **Repository URL**: Where to push Docker images
- **Repository Name**: Name of the container registry

### Useful Commands
- **kubectl config**: Command to configure kubectl
- **Docker login**: Command to authenticate with ECR
- **Docker push**: Example commands for pushing images

## Post-Deployment Setup

### Step 1: Configure kubectl

```bash
# Use the output from terraform output kubectl_config_command
aws eks update-kubeconfig --region us-east-1 --name cloudforge-cluster
```

### Step 2: Verify EKS Cluster

```bash
# Check cluster status
kubectl cluster-info

# List nodes
kubectl get nodes

# Check system pods
kubectl get pods --all-namespaces
```

**What each command verifies:**

#### `kubectl cluster-info`
- **Confirms EKS cluster is healthy and ready to accept workloads**
- Shows the Kubernetes API server endpoint
- Displays cluster version and build information
- **Expected output:**
  ```
  Kubernetes control plane is running at https://eks-xxx.us-east-1.eks.amazonaws.com
  CoreDNS is running at https://eks-xxx.us-east-1.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
  ```

#### `kubectl get nodes`
- **Verifies worker nodes are running (our t3.micro instances)**
- Shows all EC2 instances that are part of the EKS cluster
- Confirms nodes are in "Ready" status
- **Expected output:**
  ```
  NAME                    STATUS   ROLES    AGE   VERSION
  ip-10-0-11-100.ec2...  Ready    <none>   5m    v1.28.0
  ip-10-0-12-200.ec2...  Ready    <none>   5m    v1.28.0
  ```

#### `kubectl get pods --all-namespaces`
- **Checks system pods are operational (kube-system, etc.)**
- Verifies essential Kubernetes components are running
- Shows pods in kube-system namespace (CoreDNS, kube-proxy, etc.)
- **Expected output:**
  ```
  NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
  kube-system   aws-node-xxx              1/1     Running   0          5m
  kube-system   coredns-xxx                1/1     Running   0          5m
  kube-system   kube-proxy-xxx             1/1     Running   0          5m
  ```

**Why these verifications are critical:**
- **Ensures you can communicate with the Kubernetes API**
- Confirms infrastructure is ready for application deployment
- Prevents deployment failures due to cluster issues
- **Validates that your t3.micro instances are properly configured**

**Special considerations for t3.micro instances:**
- **Resource constraints**: t3.micro has limited CPU and memory (1 vCPU, 1 GB RAM)
- **System pod requirements**: Kubernetes system pods need sufficient resources
- **Performance monitoring**: Watch for resource pressure during application deployment
- **Scaling readiness**: Verify auto-scaling works when under load

**Expected resource usage on t3.micro nodes:**
```
Node Resources:
- CPU: ~200-300m used by system pods (20-30% of 1 vCPU)
- Memory: ~400-600MB used by system pods (40-60% of 1 GB)
- Available for applications: ~700-800m CPU, ~400-600MB RAM
```

### Step 3: Configure Docker for ECR

```bash
# Login to ECR (use output from terraform)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>
```

## Cost Optimization

### Current Configuration Costs
- **EKS Cluster**: ~$73/month (fixed cost)
- **EC2 Instances**: ~$16.94/month (2x t3.micro)
- **NAT Gateways**: ~$45/month (biggest cost)
- **Total**: ~$139.44/month

### Cost Reduction Options

#### Option 1: Use NAT Instances (Development)
Replace NAT Gateways with NAT Instances to save ~$80/month:
```bash
# This would require modifying the Terraform code
# NAT Instances cost ~$5/month vs NAT Gateways ~$45/month
```

#### Option 2: Single AZ Deployment
Use only one availability zone to reduce costs:
```bash
# Modify variables.tf
availability_zones = ["us-east-1a"]
```

#### Option 3: Spot Instances
Use spot instances for worker nodes:
```bash
# Modify main.tf to use spot instances
# Can save 60-90% on EC2 costs
```

## Troubleshooting

### Common Issues

#### Issue: Terraform Plan Fails
**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check Terraform version
terraform version

# Reinitialize if needed
terraform init -reconfigure
```

#### Issue: EKS Cluster Creation Fails
**Solution:**
```bash
# Check IAM permissions
aws iam get-user

# Check VPC configuration
aws ec2 describe-vpcs --vpc-ids <VPC_ID>

# Check subnet configuration
aws ec2 describe-subnets --subnet-ids <SUBNET_IDS>
```

#### Issue: kubectl Cannot Connect
**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name cloudforge-cluster

# Check cluster status
aws eks describe-cluster --name cloudforge-cluster --region us-east-1

# Verify IAM permissions
aws eks describe-cluster --name cloudforge-cluster --region us-east-1 --query 'cluster.roleArn'
```

#### Issue: EKS Cluster Verification Fails
**What to check if cluster verification commands fail:**

**If `kubectl cluster-info` fails:**
```bash
# Check if cluster is in ACTIVE state
aws eks describe-cluster --name cloudforge-cluster --region us-east-1 --query 'cluster.status'

# Verify cluster endpoint is accessible
aws eks describe-cluster --name cloudforge-cluster --region us-east-1 --query 'cluster.endpoint'
```

**If `kubectl get nodes` shows no nodes:**
```bash
# Check if node groups are healthy
aws eks describe-nodegroup --cluster-name cloudforge-cluster --nodegroup-name eks-cloudforge-node-group --region us-east-1

# Verify EC2 instances are running
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/cloudforge-cluster,Values=owned" --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'
```

**If `kubectl get pods --all-namespaces` shows failed pods:**
```bash
# Check pod logs for specific failures
kubectl logs -n kube-system <pod-name>

# Describe pod to see error details
kubectl describe pod -n kube-system <pod-name>

# Check if t3.micro instances have enough resources
kubectl describe nodes
```

### Useful Debugging Commands

```bash
# Check Terraform state
terraform state list

# View specific resource details
terraform state show aws_eks_cluster.main

# Check AWS resources directly
aws eks list-clusters
aws ecr describe-repositories
aws ec2 describe-vpcs
```

## Cleanup

### Destroy Infrastructure

```bash
# Destroy all resources (BE CAREFUL!)
terraform destroy
```

**Warning:** This will delete ALL resources and data!

### Partial Cleanup

```bash
# Remove specific resources
terraform destroy -target=aws_eks_node_group.main
terraform destroy -target=aws_eks_cluster.main
```

## Security Considerations

### Network Security
- **Private Subnets**: EKS nodes are in private subnets
- **Security Groups**: Restrict traffic to necessary ports
- **NAT Gateways**: Allow outbound internet access only

### IAM Security
- **Least Privilege**: Only necessary permissions granted
- **Role-Based Access**: Separate roles for cluster and nodes
- **No Hardcoded Credentials**: Uses AWS IAM roles

### Data Security
- **Encryption**: All storage is encrypted at rest
- **TLS**: All communication uses TLS
- **State Security**: Terraform state stored securely in S3

## Next Steps

After successful infrastructure deployment:

1. **Build Docker Image**: Create your Flask application image
2. **Push to ECR**: Upload the image to your ECR repository
3. **Deploy with Helm**: Use Helm charts to deploy to EKS
4. **Set up CI/CD**: Configure GitHub Actions for automation

## Support

If you encounter issues:

1. **Check the logs**: Use `terraform plan` and `terraform apply` output
2. **Verify permissions**: Ensure AWS credentials have required permissions
3. **Check resources**: Use AWS Console to verify resource creation
4. **Review documentation**: Check AWS EKS and Terraform documentation

## Cost Monitoring

### AWS Cost Explorer
- Monitor costs in AWS Cost Explorer
- Set up billing alerts
- Review cost optimization recommendations

### Terraform Cost Estimation
```bash
# Install terraform-cost-estimation tool
# This provides more accurate cost estimates
```

---

**Remember:** This infrastructure is designed for development and learning. For production use, consider additional security measures, monitoring, and backup strategies. 