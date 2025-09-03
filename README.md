<!-- omit in toc -->
# EKS CloudForge

- A comprehensive DevOps project demonstrating modern cloud-native application deployment on AWS EKS
- Complete CI/CD pipeline with infrastructure as code, containerization, and monitoring
- Production-ready setup with security scanning, cost optimization, and best practices

---

<div align="center">
  <img src="https://github.com/user-attachments/assets/36e4cd91-c2ac-412d-94cc-eb623c4d6956" alt="EKS CloudForge" width="500">
</div>

---

<!-- omit in toc -->
## Table of Contents

- [🚀 Overview](#-overview)
- [🏗️ Architecture](#️-architecture)
- [📋 Prerequisites](#-prerequisites)
- [⚡ Quick Start](#-quick-start)
- [📚 Documentation](#-documentation)
- [🔧 Components](#-components)
- [🔒 Security](#-security)
- [💰 Cost Optimization](#-cost-optimization)
- [🤝 Contributing](#-contributing)

---

## 🚀 Overview

**EKS CloudForge** is a comprehensive DevOps project that demonstrates modern cloud-native application deployment using industry best practices. This project showcases a complete end-to-end solution for deploying a Flask application on AWS EKS with automated CI/CD, monitoring, and security scanning.

### ✨ Key Features

- **🚀 Automated CI/CD Pipeline** - GitHub Actions with comprehensive testing and deployment
- **🏗️ Infrastructure as Code** - Terraform for AWS resource management
- **🐳 Container Orchestration** - Kubernetes with Helm charts
- **🔒 Security First** - Automated vulnerability scanning and secrets detection
- **📊 Monitoring & Observability** - Prometheus, Grafana, and cost tracking
- **💰 Cost Optimized** - Efficient resource usage with auto-scaling
- **🔄 GitOps Workflow** - Automated deployments with rollback capabilities

---

## 🏗️ Architecture

Our infrastructure includes:

- **VPC** with public and private subnets for security
- **EKS Cluster** for running Kubernetes workloads
- **ECR Repository** for storing Docker images
- **S3 Bucket** for Terraform state management
- **IAM Roles** with least-privilege access
- **Security Groups** for network isolation
- **Monitoring Stack** with Prometheus and Grafana

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### 🛠️ Required Tools

- **Docker** (v20.10+) - Container runtime
- **Terraform** (v1.5+) - Infrastructure as Code
- **kubectl** (v1.28+) - Kubernetes CLI
- **Helm** (v3.12+) - Kubernetes package manager
- **AWS CLI** (v2.0+) - AWS command line interface
- **Python** (v3.11+) - Application runtime

### ☁️ AWS Requirements

- **AWS Account** with appropriate permissions
- **IAM User** with EKS, ECR, and S3 access
- **AWS Credentials** configured locally

### 🔑 Environment Variables

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
```

---

## ⚡ Quick Start

Get up and running in minutes with our automated deployment:

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/tziyon31/EKS_CloudForge.git
cd EKS_CloudForge
```

### 2️⃣ Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (us-east-1)
```

### 3️⃣ Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4️⃣ Deploy Application

```bash
cd helm/app-chart
helm upgrade --install eks-cloudforge-app . \
  --namespace default \
  --create-namespace \
  --set image.repository=your-ecr-repo \
  --set image.tag=latest
```

### 5️⃣ Access Your Application

```bash
kubectl get svc
# Access your application at the LoadBalancer URL
```

---

## 📚 Documentation

Comprehensive documentation for every component:

### 📖 Guides

- [Application Containerization Guide](docs/application-containerization-guide.md)
- [CI/CD Pipeline Guide](docs/ci-cd-pipeline-guide.md)
- [Helm Deployment Guide](docs/helm-deployment-guide.md)
- [Terraform Deployment Guide](docs/terraform-deployment-guide.md)
- [Monitoring Deployment Guide](docs/monitoring-deployment-guide.md)

### 🎓 Tutorials

- **Getting Started** - First deployment walkthrough
- **Advanced Configuration** - Customization options
- **Troubleshooting** - Common issues and solutions
- **Best Practices** - Security and optimization tips

---

## 🔧 Components

### 📱 Application

The core Flask application with modern Python practices:

```python
from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/')
def home():
    return jsonify({"message": "Welcome to EKS CloudForge!"})
```

**Key Features:**
- RESTful API design
- Health check endpoints
- CORS support
- Error handling
- Logging integration

### 🏗️ Infrastructure

Terraform-managed AWS infrastructure with unique resource naming to avoid conflicts:

```hcl
# EKS Cluster with unique naming
resource "aws_eks_cluster" "main" {
  name = "${var.eks_cluster_name}-${random_id.unique_suffix.hex}"
  # ... configuration
}

# ECR Repository with unique naming
resource "aws_ecr_repository" "app" {
  name = "${var.ecr_repository_name}-${random_id.unique_suffix.hex}"
  # ... configuration
}
```

**Infrastructure Components:**
- **VPC** with public/private subnets
- **EKS Cluster** with managed node groups
- **ECR Repository** for container images
- **S3 Bucket** for Terraform state
- **IAM Roles** and policies
- **Security Groups** for network isolation

### 🔄 CI/CD Pipeline

GitHub Actions workflow with multiple stages:

```yaml
jobs:
  code-quality:
    runs-on: ubuntu-latest
    steps:
      - name: Run tests
        run: pytest --cov=.
      
      - name: Security scan
        run: trivy fs .
      
      - name: Build & push
        run: docker build -t $ECR_REGISTRY/$ECR_REPOSITORY .
```

**Pipeline Stages:**
1. **Code Quality** - Testing, linting, formatting
2. **Security Scanning** - Vulnerability detection
3. **Docker Build** - Container image creation
4. **Infrastructure** - Terraform deployment
5. **Application** - Helm deployment
6. **Monitoring** - Health checks and metrics

### 📊 Monitoring

Comprehensive monitoring stack:

```yaml
# Prometheus configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'kubernetes-pods'
```

**Monitoring Components:**
- **Prometheus** - Metrics collection
- **Grafana** - Visualization dashboard
- **AlertManager** - Alert routing
- **Node Exporter** - System metrics
- **Custom Metrics** - Application-specific KPIs

---

## 🔒 Security

Security-first approach with multiple layers:

### 🛡️ Security Features

- **Container Scanning** - Trivy vulnerability detection
- **Secrets Management** - Kubernetes secrets with encryption
- **Network Security** - Security groups and VPC isolation
- **IAM Roles** - Least privilege access
- **Encryption** - Data at rest and in transit
- **Compliance** - SOC 2, GDPR ready

### 🔍 Security Scanning

```yaml
# Trivy security scan
- name: Security scan
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    format: 'sarif'
    severity: 'CRITICAL'
```

### 🔐 Secrets Management

```yaml
# Kubernetes secret
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  database-url: <base64-encoded>
  api-key: <base64-encoded>
```

---

## 💰 Cost Optimization

Optimized for cost efficiency:

### 💡 Cost-Saving Strategies

- **Spot Instances** - Up to 90% cost reduction
- **Auto Scaling** - Scale based on demand
- **Resource Limits** - Prevent resource waste
- **Lifecycle Policies** - Automatic cleanup
- **Monitoring** - Cost tracking and alerts

### 📊 Cost Breakdown

| Component | Monthly Cost | Optimization |
|-----------|-------------|--------------|
| EKS Cluster | ~$73 | Use spot instances |
| Worker Nodes | ~$17 | Auto-scaling |
| ECR Storage | ~$5 | Lifecycle policies |
| Load Balancer | ~$18 | Shared across apps |
| **Total** | **~$113** | **~$60 with optimization** |

### 🎯 Optimization Tips

1. **Use Spot Instances** for non-critical workloads
2. **Implement Auto Scaling** based on metrics
3. **Set Resource Limits** to prevent over-provisioning
4. **Clean Up Resources** with lifecycle policies
5. **Monitor Costs** with AWS Cost Explorer

---

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### 🚀 Getting Started

1. **Fork the Repository**
   ```bash
   git clone https://github.com/your-username/EKS_CloudForge.git
   cd EKS_CloudForge
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make Your Changes**
   - Follow the coding standards
   - Add tests for new features
   - Update documentation

4. **Test Your Changes**
   ```bash
   # Run tests
   pytest
   
   # Run linting
   flake8
   
   # Run security scan
   trivy fs .
   ```

5. **Submit a Pull Request**
   - Provide clear description
   - Include screenshots if UI changes
   - Reference related issues

### 📋 Contribution Guidelines

- **Code Style** - Follow PEP 8 for Python
- **Documentation** - Update docs for new features
- **Testing** - Maintain >80% test coverage
- **Security** - No secrets in code
- **Performance** - Consider resource usage

---

<div align="center">

### 🌟 Star this repository if you found it helpful!

[![GitHub stars](https://img.shields.io/github/stars/tziyon31/EKS_CloudForge?style=social)](https://github.com/tziyon31/EKS_CloudForge/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/tziyon31/EKS_CloudForge?style=social)](https://github.com/tziyon31/EKS_CloudForge/network)
[![GitHub issues](https://img.shields.io/github/issues/tziyon31/EKS_CloudForge)](https://github.com/tziyon31/EKS_CloudForge/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/tziyon31/EKS_CloudForge)](https://github.com/tziyon31/EKS_CloudForge/pulls)
[![GitHub license](https://img.shields.io/github/license/tziyon31/EKS_CloudForge)](https://github.com/tziyon31/EKS_CloudForge/blob/main/LICENSE)

**Made with ❤️ by the EKS CloudForge Team**

</div>
