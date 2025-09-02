# Application Containerization Guide

## Overview
This guide covers the containerization of our Flask application, optimized for t3.micro instances and cost efficiency. We've created a lightweight, secure, and performant application that demonstrates our complete DevOps pipeline.

## Application Architecture

### Flask Application (`app/app.py`)
Our Flask application is designed specifically for t3.micro instances with the following features:

#### **Key Features:**
- **Lightweight**: Minimal dependencies, optimized for resource constraints
- **Monitoring Ready**: Built-in health checks and metrics endpoints
- **Cost Optimized**: Designed to run efficiently on t3.micro instances
- **Production Ready**: Error handling, logging, and security best practices

#### **Available Endpoints:**
- **`GET /`**: Main application page with status dashboard
- **`GET /health`**: Health check for load balancers and monitoring
- **`GET /status`**: Detailed application and system status
- **`GET /metrics`**: System metrics for monitoring and alerting
- **`GET /api/info`**: API documentation and information

#### **Resource Usage (t3.micro optimized):**
- **Memory**: ~50-100MB runtime
- **CPU**: ~200-300m (20-30% of 1 vCPU)
- **Available for scaling**: ~400-600MB RAM
- **Image size**: ~61MB

## Docker Optimization

### Multi-Stage Dockerfile (`app/Dockerfile`)

#### **Stage 1: Build Stage**
```dockerfile
FROM python:3.11-slim as builder
# Install build dependencies (gcc, g++)
# Create virtual environment
# Install Python dependencies
```

#### **Stage 2: Production Stage**
```dockerfile
FROM python:3.11-slim as production
# Copy only the virtual environment from builder
# Create non-root user for security
# Copy application code
# Set proper permissions
```

#### **Optimization Benefits:**
- **Size reduction**: ~200MB smaller than single-stage build
- **Security**: Non-root user execution
- **Performance**: Minimal runtime dependencies
- **Monitoring**: Built-in health checks

### Dependencies (`app/requirements.txt`)
Minimal, pinned dependencies for security and reproducibility:
- **Flask 3.0.0**: Lightweight web framework
- **psutil 5.9.6**: System monitoring and metrics
- **Total memory footprint**: ~20MB

### Build Context Optimization (`.dockerignore`)
Excludes unnecessary files to reduce build context size:
- **Version control**: `.git`, `.gitignore`
- **Infrastructure**: `terraform/`, `helm/`
- **Documentation**: `docs/`, `*.md`
- **Development files**: `__pycache__/`, `*.log`

## Build and Test Process

### Automated Build Script (`app/build-and-test.sh`)

#### **What the script does:**
1. **Prerequisites Check**: Verifies Docker and AWS CLI
2. **ECR Integration**: Gets repository URL from Terraform output
3. **Image Building**: Multi-stage build with detailed output
4. **Local Testing**: Runs container and tests endpoints
5. **ECR Authentication**: Logs into ECR automatically
6. **Image Push**: Tags and pushes to ECR

#### **Usage:**
```bash
cd app
./build-and-test.sh
```

### Manual Build Commands

#### **Build Image:**
```bash
docker build -t eks-cloudforge-app .
```

#### **Test Locally:**
```bash
docker run -p 5000:5000 eks-cloudforge-app
```

#### **Push to ECR:**
```bash
# Get ECR URL from Terraform output
ECR_URL=$(cd ../terraform && terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_URL

# Tag and push
docker tag eks-cloudforge-app:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

## Application Features

### **Main Dashboard (`/`)**
Beautiful, responsive web interface showing:
- **Application Status**: Health indicators
- **Resource Usage**: CPU, memory, disk usage
- **Technology Stack**: All components of our pipeline
- **Available Endpoints**: API documentation
- **Real-time Metrics**: Uptime, request count

### **Health Check (`/health`)**
Essential for load balancers and monitoring:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "uptime": "0:05:30",
  "requests_processed": 42
}
```

### **System Status (`/status`)**
Detailed system information:
```json
{
  "application": {
    "name": "EKS CloudForge",
    "version": "1.0.0",
    "status": "running"
  },
  "system": {
    "cpu_percent": 15.2,
    "memory_percent": 45.8,
    "disk_percent": 12.3
  },
  "environment": {
    "instance_type": "t3.micro",
    "region": "us-east-1"
  }
}
```

### **Metrics (`/metrics`)**
Monitoring and alerting data:
```json
{
  "metrics": {
    "cpu_usage_percent": 15.2,
    "memory_usage_percent": 45.8,
    "requests_per_minute": 8.4
  },
  "alerts": {
    "cpu_high": false,
    "memory_high": false,
    "disk_high": false
  }
}
```

## Cost Optimization Features

### **Resource Efficiency:**
- **Minimal dependencies**: Only essential packages
- **Optimized image size**: ~61MB total
- **Efficient runtime**: Low memory and CPU usage
- **Auto-scaling ready**: Designed for horizontal scaling

### **t3.micro Optimization:**
- **Memory constraints**: Designed for 1GB RAM
- **CPU constraints**: Optimized for 1 vCPU
- **Storage efficiency**: Minimal disk usage
- **Network efficiency**: Lightweight HTTP responses

### **Monitoring Integration:**
- **Built-in metrics**: No external monitoring needed
- **Health checks**: Kubernetes liveness/readiness probes
- **Resource alerts**: Automatic threshold monitoring
- **Performance tracking**: Request rate and response time

## Security Features

### **Container Security:**
- **Non-root user**: Application runs as `appuser`
- **Minimal attack surface**: Few dependencies
- **No unnecessary tools**: Only essential runtime components
- **Regular updates**: Pinned versions for security

### **Application Security:**
- **Input validation**: All endpoints validate input
- **Error handling**: Graceful error responses
- **No sensitive data**: No secrets in application code
- **HTTPS ready**: Designed for TLS termination

## Testing and Validation

### **Local Testing:**
```bash
# Start application
docker run -p 5000:5000 eks-cloudforge-app

# Test endpoints
curl http://localhost:5000/health
curl http://localhost:5000/status
curl http://localhost:5000/metrics
```

### **Health Check Validation:**
```bash
# Test health endpoint
curl -f http://localhost:5000/health || echo "Health check failed"

# Test main application
curl -f http://localhost:5000/ || echo "Main app failed"
```

### **Resource Usage Validation:**
```bash
# Check container resource usage
docker stats $(docker ps -q --filter ancestor=eks-cloudforge-app)

# Monitor application metrics
curl http://localhost:5000/metrics | jq '.metrics'
```

## Integration with Infrastructure

### **ECR Integration:**
- **Automatic authentication**: Uses AWS IAM roles
- **Terraform integration**: Gets repository URL from outputs
- **Version management**: Supports multiple image tags
- **Lifecycle policies**: Automatic cleanup of old images

### **EKS Integration:**
- **Kubernetes ready**: Health checks for liveness/readiness
- **Resource limits**: Configured for t3.micro constraints
- **Auto-scaling**: Horizontal Pod Autoscaler ready
- **Monitoring**: Metrics for Prometheus/Grafana

### **CI/CD Integration:**
- **GitHub Actions ready**: Automated build and push
- **Docker Hub compatible**: Can push to any registry
- **Multi-arch support**: Ready for ARM64 if needed
- **Rollback capability**: Multiple image versions

## Troubleshooting

### **Common Issues:**

#### **Build Fails:**
```bash
# Check Docker daemon
docker info

# Check build context
docker build --progress=plain .

# Check disk space
df -h
```

#### **Container Won't Start:**
```bash
# Check container logs
docker logs <container_id>

# Check resource constraints
docker stats <container_id>

# Test health endpoint
curl http://localhost:5000/health
```

#### **High Resource Usage:**
```bash
# Check application metrics
curl http://localhost:5000/metrics

# Monitor system resources
docker stats <container_id>

# Check for memory leaks
docker exec <container_id> ps aux
```

### **Performance Optimization:**
- **Reduce image size**: Use multi-stage builds
- **Optimize dependencies**: Remove unused packages
- **Tune resource limits**: Adjust CPU/memory constraints
- **Monitor metrics**: Use built-in monitoring endpoints

## Next Steps

After successful containerization:

1. **Deploy to EKS**: Use Helm charts for deployment
2. **Set up monitoring**: Configure Prometheus/Grafana
3. **Configure auto-scaling**: Set up HPA
4. **Set up CI/CD**: Configure GitHub Actions
5. **Performance tuning**: Monitor and optimize

## Best Practices

### **Development:**
- **Local testing**: Always test before pushing
- **Version pinning**: Use exact versions for reproducibility
- **Security scanning**: Scan images for vulnerabilities
- **Documentation**: Keep guides updated

### **Production:**
- **Resource limits**: Set appropriate CPU/memory limits
- **Health checks**: Configure liveness/readiness probes
- **Monitoring**: Set up alerts for resource usage
- **Backup strategy**: Regular image backups

---

**The application is now ready for deployment to EKS!** 🚀 