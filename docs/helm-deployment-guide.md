# Helm Chart Deployment Guide

## Overview
This guide covers the deployment of our EKS CloudForge application using Helm charts. The Helm chart is optimized for t3.micro instances and includes comprehensive configuration options for production deployment.

## Helm Chart Structure

### **Chart Components:**
```
helm/app-chart/
├── Chart.yaml              # Chart metadata and version info
├── values.yaml             # Default configuration values
└── templates/              # Kubernetes manifest templates
    ├── helpers.tpl         # Reusable template functions
    ├── deployment.yaml     # Pod deployment configuration
    ├── service.yaml        # Service for network access
    ├── ingress.yaml        # External traffic routing
    ├── hpa.yaml           # Horizontal Pod Autoscaler
    ├── pdb.yaml           # Pod Disruption Budget
    ├── configmap.yaml     # Configuration data
    ├── secret.yaml        # Sensitive data (if needed)
    └── NOTES.txt          # Post-deployment instructions
```

### **Key Features:**
- **Cost Optimized**: Designed for t3.micro instances
- **Auto-scaling**: Horizontal Pod Autoscaler with CPU/Memory metrics
- **High Availability**: Pod Disruption Budget and anti-affinity
- **Security**: Non-root user, security contexts, health checks
- **Monitoring**: Prometheus metrics, health checks, logging
- **Flexible Configuration**: Extensive values.yaml options

## Prerequisites

### **Required Tools:**
```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version

# Install kubectl (if not already installed)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### **Required Infrastructure:**
- **EKS Cluster**: Running and accessible
- **ECR Repository**: Docker images pushed
- **kubectl**: Configured for EKS cluster
- **Ingress Controller**: NGINX Ingress Controller installed

## Configuration Options

### **Core Configuration (`values.yaml`)**

#### **Image Configuration:**
```yaml
image:
  repository: "123456789012.dkr.ecr.us-east-1.amazonaws.com/cloudforge-app"
  tag: "latest"
  pullPolicy: IfNotPresent
```

#### **Deployment Configuration:**
```yaml
deployment:
  replicas: 2                    # Number of replicas
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

#### **Resource Limits (t3.micro optimized):**
```yaml
resources:
  requests:
    cpu: "200m"        # 20% of 1 vCPU
    memory: "256Mi"    # 25% of 1GB RAM
  limits:
    cpu: "500m"        # 50% of 1 vCPU
    memory: "512Mi"    # 50% of 1GB RAM
```

#### **Auto-scaling Configuration:**
```yaml
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 4
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

## Deployment Process

### **Step 1: Prepare Environment**

```bash
# Navigate to the Helm chart directory
cd helm/app-chart

# Verify chart structure
helm lint .

# Check what will be deployed (dry run)
helm template . --dry-run
```

### **Step 2: Configure Values**

#### **Create Custom Values File:**
```bash
# Create custom values file
cat > custom-values.yaml << EOF
# Custom configuration
image:
  repository: "123456789012.dkr.ecr.us-east-1.amazonaws.com/cloudforge-app"
  tag: "latest"

deployment:
  replicas: 2

resources:
  requests:
    cpu: "200m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 4

ingress:
  enabled: true
  hosts:
    - host: eks-cloudforge.local
      paths:
        - path: /
          pathType: Prefix
EOF
```

#### **Environment-Specific Values:**
```bash
# Development values
cat > values-dev.yaml << EOF
global:
  labels:
    environment: "dev"

deployment:
  replicas: 1

autoscaling:
  maxReplicas: 2

debugging:
  debug: true
  verbose: true
EOF

# Production values
cat > values-prod.yaml << EOF
global:
  labels:
    environment: "prod"

deployment:
  replicas: 3

autoscaling:
  maxReplicas: 6

security:
  runAsNonRoot: true
  readOnlyRootFilesystem: true

monitoring:
  serviceMonitor:
    enabled: true
EOF
```

### **Step 3: Deploy the Application**

#### **Basic Deployment:**
```bash
# Deploy with default values
helm install eks-cloudforge-app . -n default

# Deploy with custom values
helm install eks-cloudforge-app . -f custom-values.yaml -n default

# Deploy with environment-specific values
helm install eks-cloudforge-app . -f values-dev.yaml -n default
```

#### **Advanced Deployment Options:**
```bash
# Deploy with specific values overrides
helm install eks-cloudforge-app . \
  --set image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/cloudforge-app \
  --set image.tag=latest \
  --set deployment.replicas=2 \
  --set autoscaling.enabled=true \
  --set ingress.enabled=true \
  -n default

# Deploy with wait for resources
helm install eks-cloudforge-app . \
  --wait \
  --timeout 10m \
  --atomic \
  -n default
```

### **Step 4: Verify Deployment**

#### **Check Deployment Status:**
```bash
# Check Helm release status
helm list -n default

# Check deployment status
kubectl get deployment eks-cloudforge-app -n default

# Check pod status
kubectl get pods -l app=eks-cloudforge-app -n default

# Check service status
kubectl get service eks-cloudforge-app-service -n default
```

#### **Check Application Health:**
```bash
# Port forward to access application
kubectl port-forward service/eks-cloudforge-app-service 8080:80 -n default

# Test health endpoint
curl http://localhost:8080/health

# Test main application
curl http://localhost:8080/

# Test metrics endpoint
curl http://localhost:8080/metrics
```

## Configuration Options

### **Resource Management**

#### **CPU and Memory Limits:**
```yaml
resources:
  requests:
    cpu: "200m"        # Minimum guaranteed CPU
    memory: "256Mi"    # Minimum guaranteed memory
  limits:
    cpu: "500m"        # Maximum allowed CPU
    memory: "512Mi"    # Maximum allowed memory
```

#### **Node Affinity (t3.micro preference):**
```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
            - key: node.kubernetes.io/instance-type
              operator: In
              values:
                - t3.micro
```

### **Auto-scaling Configuration**

#### **Horizontal Pod Autoscaler:**
```yaml
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 4
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
```

### **Security Configuration**

#### **Security Context:**
```yaml
security:
  runAsNonRoot: true
  readOnlyRootFilesystem: false
  allowPrivilegeEscalation: false
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    capabilities:
      drop:
        - ALL
```

#### **Health Checks:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

### **Network Configuration**

#### **Service Configuration:**
```yaml
service:
  type: ClusterIP
  port: 80
  targetPort: 5000
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"
```

#### **Ingress Configuration:**
```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
  hosts:
    - host: eks-cloudforge.local
      paths:
        - path: /
          pathType: Prefix
```

## Monitoring and Observability

### **Built-in Metrics:**
- **Application Metrics**: `/metrics` endpoint
- **Health Checks**: `/health` endpoint
- **System Status**: `/status` endpoint

### **Prometheus Integration:**
```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: false
    interval: 30s
    path: /metrics
    port: 5000
```

### **Logging Configuration:**
```bash
# View application logs
kubectl logs -l app=eks-cloudforge-app -n default

# Follow logs in real-time
kubectl logs -l app=eks-cloudforge-app -f -n default

# View logs from specific pod
kubectl logs <pod-name> -n default
```

## Updating and Maintenance

### **Upgrade Deployment:**
```bash
# Upgrade with new values
helm upgrade eks-cloudforge-app . -f custom-values.yaml -n default

# Upgrade with specific values
helm upgrade eks-cloudforge-app . \
  --set image.tag=v1.1.0 \
  --set deployment.replicas=3 \
  -n default

# Rollback if needed
helm rollback eks-cloudforge-app 1 -n default
```

### **Scaling Operations:**
```bash
# Scale deployment manually
kubectl scale deployment eks-cloudforge-app --replicas=3 -n default

# Check HPA status
kubectl get hpa eks-cloudforge-app-hpa -n default

# Describe HPA for detailed info
kubectl describe hpa eks-cloudforge-app-hpa -n default
```

### **Configuration Updates:**
```bash
# Update ConfigMap
kubectl patch configmap eks-cloudforge-app-config \
  -p '{"data":{"LOG_LEVEL":"DEBUG"}}' \
  -n default

# Restart pods to pick up new config
kubectl rollout restart deployment eks-cloudforge-app -n default
```

## Troubleshooting

### **Common Issues:**

#### **1. Pods Not Starting:**
```bash
# Check pod events
kubectl describe pod -l app=eks-cloudforge-app -n default

# Check pod logs
kubectl logs -l app=eks-cloudforge-app -n default

# Check resource constraints
kubectl top pods -l app=eks-cloudforge-app -n default
```

#### **2. Health Checks Failing:**
```bash
# Check health endpoint directly
kubectl exec -it $(kubectl get pod -l app=eks-cloudforge-app -n default -o jsonpath='{.items[0].metadata.name}') -n default -- curl http://localhost:5000/health

# Check probe configuration
kubectl describe pod -l app=eks-cloudforge-app -n default | grep -A 10 "Liveness"
```

#### **3. Auto-scaling Not Working:**
```bash
# Check HPA status
kubectl get hpa eks-cloudforge-app-hpa -n default

# Check metrics server
kubectl get pods -n kube-system | grep metrics-server

# Check resource usage
kubectl top pods -l app=eks-cloudforge-app -n default
```

#### **4. Ingress Not Working:**
```bash
# Check ingress status
kubectl get ingress eks-cloudforge-app-ingress -n default

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check service endpoints
kubectl get endpoints eks-cloudforge-app-service -n default
```

### **Debugging Commands:**
```bash
# Get all resources for this release
kubectl get all -l app=eks-cloudforge-app -n default

# Check events
kubectl get events --sort-by='.lastTimestamp' -n default

# Check resource usage
kubectl top pods -l app=eks-cloudforge-app -n default

# Check node resources
kubectl top nodes
```

## Cost Optimization

### **Resource Optimization:**
- **CPU Requests**: 200m (20% of t3.micro)
- **Memory Requests**: 256Mi (25% of t3.micro)
- **CPU Limits**: 500m (50% of t3.micro)
- **Memory Limits**: 512Mi (50% of t3.micro)

### **Scaling Optimization:**
- **Min Replicas**: 1 (minimum cost)
- **Max Replicas**: 4 (limited by t3.micro resources)
- **Scale Down**: Conservative (5 minutes stabilization)
- **Scale Up**: Aggressive (1 minute stabilization)

### **Cost Monitoring:**
```bash
# Monitor resource usage
kubectl top pods -l app=eks-cloudforge-app -n default

# Check HPA scaling
kubectl describe hpa eks-cloudforge-app-hpa -n default

# Monitor costs via AWS Cost Explorer
# Set up billing alerts for EKS resources
```

## Best Practices

### **Security:**
- **Non-root user**: Always run as non-root
- **Security contexts**: Configure proper security contexts
- **Resource limits**: Set appropriate CPU/memory limits
- **Health checks**: Configure liveness/readiness probes
- **Network policies**: Restrict network access if needed

### **Performance:**
- **Resource requests**: Set appropriate resource requests
- **Auto-scaling**: Enable HPA for dynamic scaling
- **Monitoring**: Monitor resource usage and performance
- **Logging**: Configure proper logging and log rotation

### **Reliability:**
- **Pod Disruption Budget**: Ensure high availability
- **Anti-affinity**: Spread pods across nodes
- **Health checks**: Monitor application health
- **Rolling updates**: Use rolling update strategy

### **Maintenance:**
- **Regular updates**: Keep images and dependencies updated
- **Backup**: Backup configuration and data
- **Monitoring**: Set up alerts for critical metrics
- **Documentation**: Keep deployment documentation updated

## Next Steps

After successful Helm deployment:

1. **Set up monitoring**: Configure Prometheus/Grafana
2. **Configure custom domain**: Set up DNS and SSL certificates
3. **Set up CI/CD**: Configure automated deployment pipeline
4. **Performance tuning**: Monitor and optimize performance
5. **Security hardening**: Implement additional security measures
6. **Backup strategy**: Set up regular backups

---

**Your Helm chart is now ready for deployment!** 🚀 