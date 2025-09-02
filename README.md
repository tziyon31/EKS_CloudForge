# EKS_CloudForge - Complete DevOps Pipeline

## Project Overview
This project demonstrates a complete DevOps pipeline for deploying a Flask application to AWS EKS using modern cloud-native practices.

### What We're Building
- **Infrastructure as Code**: AWS resources managed with Terraform
- **Containerization**: Flask app packaged with Docker
- **Kubernetes Deployment**: Helm charts for EKS deployment
- **CI/CD Automation**: GitHub Actions for automated deployment
- **Monitoring**: Application and infrastructure monitoring

### Project Structure
```
EKS_CloudForge/
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # Main Terraform configuration
│   ├── variables.tf    # Input variables
│   ├── outputs.tf      # Output values
│   └── providers.tf    # Provider configuration
├── app/                # Application code
│   ├── app.py         # Flask application
│   ├── requirements.txt # Python dependencies
│   └── Dockerfile     # Container configuration
├── helm/              # Kubernetes deployment
│   └── app-chart/     # Helm chart for the application
│       ├── Chart.yaml     # Chart metadata and version info
│       ├── values.yaml    # Default configuration values
│       └── templates/     # Kubernetes manifest templates
│           ├── helpers.tpl      # Reusable template functions
│           ├── deployment.yaml  # Pod deployment configuration
│           ├── service.yaml     # Service for network access
│           ├── ingress.yaml     # External traffic routing
│           ├── configmap.yaml   # Configuration data
│           └── secret.yaml      # Sensitive data (if needed)
├── .github/           # GitHub Actions workflows
│   └── workflows/     # CI/CD pipeline definitions
├── monitoring/        # Monitoring configuration
└── docs/             # Documentation
```

### Prerequisites
- AWS CLI configured
- Terraform installed
- Docker installed
- kubectl configured
- Helm installed

### Quick Start
1. Clone this repository
2. Follow the step-by-step deployment guide in `docs/`
3. Run the infrastructure setup
4. Deploy the application

## Architecture Overview
Our infrastructure will include:
- **VPC** with public and private subnets for security
- **EKS Cluster** for running Kubernetes workloads
- **ECR Repository** for storing Docker images
- **S3 Bucket** for Terraform state management
- **IAM Roles** with least-privilege access

## Security & Best Practices
- Network segmentation with public/private subnets
- Least-privilege IAM policies
- Encrypted storage and communication
- Regular security updates and monitoring