# CI/CD Pipeline Guide

## Overview
This guide covers the comprehensive CI/CD pipeline for the EKS CloudForge project. The pipeline automates testing, building, security scanning, infrastructure deployment, and application deployment.

## Pipeline Architecture

### **Pipeline Components:**
```
GitHub Actions Workflow
├── Code Quality & Testing
├── Security Scanning
├── Docker Build & Push
├── Infrastructure Deployment
├── Application Deployment
├── Monitoring & Cost Tracking
└── Cleanup (on failure)
```

### **Key Features:**
- **Automated Testing**: Unit, integration, performance, and security tests
- **Security Scanning**: Trivy, Bandit, and secret detection
- **Multi-Environment Support**: dev, staging, prod
- **Infrastructure as Code**: Terraform automation
- **Container Management**: Docker build and ECR push
- **Kubernetes Deployment**: Helm automation
- **Cost Monitoring**: Resource usage tracking
- **Failure Recovery**: Automatic cleanup on failures

## Pipeline Workflow

### **1. Code Quality & Testing**
```yaml
code-quality:
  - Python setup and dependency installation
  - Code formatting check (Black, isort)
  - Linting (Flake8)
  - Unit and integration tests (pytest)
  - Coverage reporting
  - Terraform validation
  - Helm chart linting
```

### **2. Security Scanning**
```yaml
security-scan:
  - Trivy vulnerability scanning
  - Bandit security linting
  - TruffleHog secret detection
  - SARIF report generation
```

### **3. Docker Build & Push**
```yaml
docker-build:
  - AWS ECR login
  - Multi-stage Docker build
  - Image tagging and pushing
  - Container security scanning
```

### **4. Infrastructure Deployment**
```yaml
infrastructure:
  - Terraform initialization
  - Workspace management
  - Plan and apply
  - Output extraction
```

### **5. Application Deployment**
```yaml
application-deployment:
  - kubectl configuration
  - Helm deployment
  - Health verification
  - Smoke tests
```

### **6. Monitoring & Cost Tracking**
```yaml
monitoring:
  - Application health checks
  - Resource usage monitoring
  - Cost estimation
  - Deployment reporting
```

## Configuration

### **Environment Variables**
```yaml
env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: cloudforge-app
  APP_NAME: eks-cloudforge-app
  APP_VERSION: ${{ github.sha }}
  TF_WORKSPACE: ${{ github.event.inputs.environment || 'dev' }}
  TF_VAR_ENVIRONMENT: ${{ github.event.inputs.environment || 'dev' }}
  TRIVY_SEVERITY: CRITICAL,HIGH
  COST_ALERT_THRESHOLD: 50
```

### **Required Secrets**
```yaml
secrets:
  AWS_ACCESS_KEY_ID: AWS access key for ECR and EKS
  AWS_SECRET_ACCESS_KEY: AWS secret key for ECR and EKS
```

### **Environment Protection**
```yaml
environments:
  dev:
    protection_rules:
      - required_reviewers: 1
      - required_status_checks: []
  staging:
    protection_rules:
      - required_reviewers: 2
      - required_status_checks: ["code-quality", "security-scan"]
  prod:
    protection_rules:
      - required_reviewers: 3
      - required_status_checks: ["code-quality", "security-scan", "docker-build"]
```

## Usage

### **Automatic Triggers**
```yaml
# Push to main/develop branches
on:
  push:
    branches: [main, develop]
    paths: ['app/**', 'terraform/**', 'helm/**']

# Pull requests
on:
  pull_request:
    branches: [main, develop]
```

### **Manual Triggers**
```yaml
# Manual workflow dispatch
workflow_dispatch:
  inputs:
    environment: [dev, staging, prod]
    skip_infrastructure: [true, false]
    skip_security_scan: [true, false]
```

### **Running the Pipeline**

#### **1. Automatic Deployment (Push to main)**
```bash
# Push changes to trigger automatic deployment
git push origin main
```

#### **2. Manual Deployment**
```bash
# Go to GitHub Actions tab
# Click "Run workflow"
# Select environment and options
# Click "Run workflow"
```

#### **3. Pull Request Checks**
```bash
# Create pull request
# Pipeline runs automatically
# Review results before merge
```

## Testing Strategy

### **Test Types**

#### **Unit Tests**
```python
# Test individual functions and components
def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert data['status'] == 'healthy'
```

#### **Integration Tests**
```python
# Test component interactions
def test_full_request_cycle(client):
    response = client.get('/')
    assert response.status_code == 200
    response = client.get('/health')
    assert response.status_code == 200
```

#### **Performance Tests**
```python
# Test response times and resource usage
def test_response_time(client):
    start_time = time.time()
    response = client.get('/health')
    end_time = time.time()
    assert (end_time - start_time) < 0.5
```

#### **Security Tests**
```python
# Test security features
def test_input_validation(client):
    response = client.get('/health?param=<script>alert("xss")</script>')
    assert response.status_code == 200
```

### **Test Coverage**
```bash
# Run tests with coverage
pytest --cov=app --cov-report=html --cov-report=xml
```

## Security Scanning

### **Trivy Vulnerability Scanner**
```yaml
# Scan filesystem for vulnerabilities
trivy fs --severity CRITICAL,HIGH --format sarif --output trivy-results.sarif .
```

### **Bandit Security Linter**
```yaml
# Scan Python code for security issues
bandit -r . -f json -o bandit-report.json
```

### **TruffleHog Secret Detection**
```yaml
# Scan for secrets in code
trufflehog --only-verified .
```

## Docker Build Process

### **Multi-Stage Build**
```dockerfile
# Build stage
FROM python:3.11-slim as builder
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Production stage
FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local
COPY app/ /app/
```

### **Image Optimization**
```yaml
# Optimizations for t3.micro
- Multi-stage build reduces image size
- Non-root user for security
- Minimal dependencies
- Health checks included
```

## Infrastructure Deployment

### **Terraform Workflow**
```bash
# Initialize Terraform
terraform init

# Select workspace
terraform workspace select dev

# Plan changes
terraform plan -var="environment=dev" -out=tfplan

# Apply changes
terraform apply tfplan
```

### **Workspace Management**
```bash
# Create environment-specific workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

## Application Deployment

### **Helm Deployment**
```bash
# Deploy with Helm
helm upgrade --install eks-cloudforge-app . \
  --namespace default \
  --set image.repository=$ECR_URL \
  --set image.tag=$VERSION \
  --wait --timeout 10m --atomic
```

### **Health Verification**
```bash
# Check pod status
kubectl get pods -l app=eks-cloudforge-app

# Check service status
kubectl get services -l app=eks-cloudforge-app

# Run smoke tests
curl -f http://$SERVICE_URL/health
```

## Monitoring and Cost Tracking

### **Resource Monitoring**
```bash
# Check resource usage
kubectl top pods -l app=eks-cloudforge-app

# Check HPA status
kubectl get hpa -l app=eks-cloudforge-app
```

### **Cost Estimation**
```bash
# Calculate estimated costs
INSTANCE_COUNT=$(kubectl get nodes --no-headers | wc -l)
ESTIMATED_COST=$((INSTANCE_COUNT * 8))  # $8 per t3.micro
```

### **Cost Alerts**
```yaml
# Alert if cost exceeds threshold
if [ $ESTIMATED_COST -gt $COST_ALERT_THRESHOLD ]; then
  echo "⚠️ Cost alert: $${ESTIMATED_COST} exceeds $${COST_ALERT_THRESHOLD}"
  exit 1
fi
```

## Failure Recovery

### **Automatic Cleanup**
```yaml
cleanup:
  if: failure() && github.ref == 'refs/heads/main'
  steps:
    - terraform destroy -auto-approve
    - aws ecr batch-delete-image
```

### **Manual Cleanup**
```bash
# Clean up infrastructure
cd terraform
terraform destroy -auto-approve

# Clean up ECR images
aws ecr batch-delete-image --repository-name cloudforge-app --image-ids imageTag=$VERSION
```

## Best Practices

### **Security**
- **Secret Management**: Use GitHub Secrets for sensitive data
- **Environment Protection**: Require reviews for production deployments
- **Security Scanning**: Run scans on every build
- **Least Privilege**: Use minimal AWS permissions

### **Reliability**
- **Atomic Deployments**: Use `--atomic` flag for Helm
- **Rollback Strategy**: Keep previous versions for quick rollback
- **Health Checks**: Verify deployment before marking as complete
- **Failure Recovery**: Automatic cleanup on failures

### **Performance**
- **Parallel Jobs**: Run independent jobs in parallel
- **Caching**: Cache dependencies and build artifacts
- **Resource Limits**: Set appropriate timeouts and resource limits
- **Optimization**: Use multi-stage builds and minimal images

### **Cost Optimization**
- **Resource Monitoring**: Track resource usage
- **Cost Alerts**: Set up alerts for cost thresholds
- **Cleanup**: Remove unused resources
- **Optimization**: Use t3.micro instances and auto-scaling

## Troubleshooting

### **Common Issues**

#### **1. Build Failures**
```bash
# Check build logs
# Verify dependencies
# Check Dockerfile syntax
# Ensure sufficient disk space
```

#### **2. Deployment Failures**
```bash
# Check pod events
kubectl describe pod -l app=eks-cloudforge-app

# Check logs
kubectl logs -l app=eks-cloudforge-app

# Check resource constraints
kubectl top pods -l app=eks-cloudforge-app
```

#### **3. Infrastructure Failures**
```bash
# Check Terraform logs
# Verify AWS credentials
# Check resource limits
# Review Terraform plan
```

#### **4. Security Scan Failures**
```bash
# Review vulnerability reports
# Update dependencies
# Fix security issues
# Re-run scans
```

### **Debugging Commands**
```bash
# Check workflow status
gh run list

# View workflow logs
gh run view $RUN_ID --log

# Rerun failed jobs
gh run rerun $RUN_ID

# Cancel running workflow
gh run cancel $RUN_ID
```

## Next Steps

After successful CI/CD setup:

1. **Set up monitoring**: Configure Prometheus/Grafana
2. **Add notifications**: Slack, email, or webhook notifications
3. **Implement blue-green deployments**: Zero-downtime deployments
4. **Add performance testing**: Load testing and performance monitoring
5. **Implement feature flags**: Gradual feature rollouts
6. **Add compliance scanning**: SOC2, PCI, or other compliance checks

---

**Your CI/CD pipeline is now ready for automated deployments!** 🚀
