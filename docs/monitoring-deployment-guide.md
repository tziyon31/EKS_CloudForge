# Monitoring & Observability Deployment Guide

## Overview

This guide covers the deployment of a comprehensive monitoring and observability stack for the EKS CloudForge project. The stack includes Prometheus for metrics collection, Grafana for visualization, and AlertManager for alerting, all optimized for t3.micro instances.

## Architecture

### **Monitoring Stack Components:**

```
EKS CloudForge Monitoring Stack
├── Prometheus (Metrics Collection)
│   ├── Time-series database
│   ├── Alert rules engine
│   └── Service discovery
├── Grafana (Visualization)
│   ├── Custom dashboards
│   ├── Cost monitoring
│   └── Performance metrics
├── AlertManager (Alerting)
│   ├── Alert routing
│   ├── Notification channels
│   └── Alert grouping
└── Custom Resources
    ├── ServiceMonitor
    ├── PodMonitor
    └── PrometheusRule
```

### **Key Features:**

- **Cost-Optimized**: Minimal resource usage for t3.micro instances
- **Custom Dashboards**: Application-specific monitoring
- **Cost Monitoring**: Real-time cost tracking and alerts
- **Auto-Scaling Integration**: HPA metrics and alerts
- **Security**: Non-root containers and minimal permissions
- **High Availability**: Persistent storage and backup

## Prerequisites

### **Required Tools:**

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### **Cluster Requirements:**

- **EKS Cluster**: Running and accessible
- **Storage Class**: `gp2` available
- **Ingress Controller**: NGINX Ingress Controller
- **Resource Availability**: At least 500m CPU and 640Mi RAM

### **Access Requirements:**

```bash
# Verify cluster access
kubectl cluster-info

# Check available storage classes
kubectl get storageclass

# Verify ingress controller
kubectl get pods -n ingress-nginx
```

## Deployment Options

### **Option 1: Automated Deployment (Recommended)**

```bash
# Make script executable
chmod +x monitoring/deploy-monitoring.sh

# Run deployment
./monitoring/deploy-monitoring.sh
```

### **Option 2: Manual Deployment**

#### **Step 1: Create Namespace**

```bash
kubectl create namespace monitoring
```

#### **Step 2: Add Helm Repositories**

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

#### **Step 3: Deploy Prometheus**

```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --version 25.0.0 \
    --values monitoring/prometheus/values.yaml \
    --wait \
    --timeout 10m \
    --atomic
```

#### **Step 4: Deploy Grafana**

```bash
helm upgrade --install grafana grafana/grafana \
    --namespace monitoring \
    --version 7.0.0 \
    --values monitoring/grafana/values.yaml \
    --wait \
    --timeout 10m \
    --atomic
```

## Configuration Details

### **Prometheus Configuration**

#### **Resource Limits (t3.micro optimized):**

```yaml
resources:
  requests:
    cpu: 100m        # 10% of 1 vCPU
    memory: 128Mi    # 12.5% of 1GB RAM
  limits:
    cpu: 200m        # 20% of 1 vCPU
    memory: 256Mi    # 25% of 1GB RAM
```

#### **Storage Configuration:**

```yaml
storageSpec:
  volumeClaimTemplate:
    spec:
      storageClassName: gp2
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 5Gi  # ~$0.50/month
```

#### **Scrape Configuration:**

```yaml
scrapeInterval: 30s      # Collect metrics every 30 seconds
evaluationInterval: 30s  # Evaluate rules every 30 seconds
retention: 7d           # Keep data for 7 days
retentionSize: "2GB"    # Limit storage to 2GB
```

### **Grafana Configuration**

#### **Resource Limits:**

```yaml
resources:
  requests:
    cpu: 100m        # 10% of 1 vCPU
    memory: 128Mi    # 12.5% of 1GB RAM
  limits:
    cpu: 200m        # 20% of 1 vCPU
    memory: 256Mi    # 25% of 1GB RAM
```

#### **Storage Configuration:**

```yaml
persistence:
  enabled: true
  storageClassName: gp2
  accessMode: ReadWriteOnce
  size: 2Gi  # ~$0.20/month
```

#### **Access Configuration:**

```yaml
adminUser: admin
adminPassword: admin123
ingress:
  enabled: true
  hosts:
    - host: grafana.eks-cloudforge.local
```

### **AlertManager Configuration**

#### **Resource Limits:**

```yaml
resources:
  requests:
    cpu: 50m         # 5% of 1 vCPU
    memory: 64Mi     # 6.25% of 1GB RAM
  limits:
    cpu: 100m        # 10% of 1 vCPU
    memory: 128Mi    # 12.5% of 1GB RAM
```

#### **Alert Configuration:**

```yaml
config:
  global:
    resolve_timeout: 5m
  route:
    group_by: ['alertname']
    group_wait: 10s
    group_interval: 10s
    repeat_interval: 1h
    receiver: 'web.hook'
  receivers:
    - name: 'web.hook'
      webhook_configs:
        - url: 'http://127.0.0.1:5001/'
```

## Custom Resources

### **ServiceMonitor**

Monitors the EKS CloudForge application service:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: eks-cloudforge-app
  namespace: monitoring
  labels:
    app: eks-cloudforge-app
spec:
  selector:
    matchLabels:
      app: eks-cloudforge-app
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s
  namespaceSelector:
    matchNames:
      - default
```

### **PodMonitor**

Monitors individual pods for more detailed metrics:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: eks-cloudforge-app
  namespace: monitoring
  labels:
    app: eks-cloudforge-app
spec:
  selector:
    matchLabels:
      app: eks-cloudforge-app
  podMetricsEndpoints:
    - port: http
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s
```

### **PrometheusRule**

Defines alerting rules for the application:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: eks-cloudforge-app
  namespace: monitoring
  labels:
    app: eks-cloudforge-app
spec:
  groups:
    - name: eks-cloudforge-app
      interval: 30s
      rules:
        - alert: HighCPUUsage
          expr: container_cpu_usage_seconds_total{container="eks-cloudforge-app"} > 0.8
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High CPU usage detected"
            description: "Container {{ $labels.container }} has high CPU usage"
```

## Dashboards

### **EKS CloudForge Application Dashboard**

The custom dashboard includes:

#### **Performance Metrics:**
- **CPU Usage**: Real-time CPU utilization
- **Memory Usage**: Memory consumption tracking
- **Response Time**: HTTP request duration
- **Request Rate**: Requests per second

#### **Cost Metrics:**
- **Estimated Cost**: Per-hour cost calculation
- **Resource Efficiency**: CPU/memory utilization
- **Auto-scaling Impact**: HPA scaling events

#### **Operational Metrics:**
- **Pod Status**: Running pods count
- **Error Rate**: 5xx error percentage
- **Disk Usage**: Container filesystem usage

### **Dashboard Panels:**

1. **CPU Usage Graph**: Shows CPU utilization over time
2. **Memory Usage Graph**: Displays memory consumption
3. **Response Time Graph**: HTTP request duration
4. **Request Rate Graph**: Requests per second
5. **Current Metrics Stats**: Real-time values
6. **Running Pods**: Pod count over time
7. **Estimated Cost**: Cost per hour
8. **Error Rate**: Error percentage
9. **Disk Usage**: Filesystem usage

## Alerts

### **Alert Rules:**

#### **High CPU Usage:**
```yaml
- alert: HighCPUUsage
  expr: container_cpu_usage_seconds_total{container="eks-cloudforge-app"} > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High CPU usage detected"
    description: "Container {{ $labels.container }} has high CPU usage"
    cost_impact: "May trigger auto-scaling"
```

#### **High Memory Usage:**
```yaml
- alert: HighMemoryUsage
  expr: container_memory_usage_bytes{container="eks-cloudforge-app"} > 800000000
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High memory usage detected"
    description: "Container {{ $labels.container }} has high memory usage"
    cost_impact: "May trigger auto-scaling"
```

#### **Pod Down:**
```yaml
- alert: PodDown
  expr: up{job="eks-cloudforge-app"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Pod is down"
    description: "Pod {{ $labels.pod }} is down"
    cost_impact: "Service unavailable"
```

#### **High Response Time:**
```yaml
- alert: HighResponseTime
  expr: http_request_duration_seconds{job="eks-cloudforge-app"} > 2
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High response time detected"
    description: "Response time is high for {{ $labels.instance }}"
    cost_impact: "Poor user experience"
```

#### **High Cost:**
```yaml
- alert: HighCost
  expr: increase(container_cpu_usage_seconds_total{container="eks-cloudforge-app"}[1h]) > 3600
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "High cost detected"
    description: "High CPU usage over 1 hour"
    cost_impact: "May exceed budget"
```

## Cost Optimization

### **Resource Allocation:**

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage |
|-----------|-------------|-----------|----------------|--------------|---------|
| Prometheus | 100m | 200m | 128Mi | 256Mi | 5Gi |
| AlertManager | 50m | 100m | 64Mi | 128Mi | 1Gi |
| Grafana | 100m | 200m | 128Mi | 256Mi | 2Gi |
| **Total** | **250m** | **500m** | **320Mi** | **640Mi** | **8Gi** |

### **Cost Breakdown:**

- **Storage Costs**: ~$0.80/month (8Gi total)
- **Compute Costs**: Included in EKS node costs
- **Total Monitoring Cost**: ~$1.50/month

### **Optimization Strategies:**

1. **Reduced Scrape Interval**: 30s instead of 15s
2. **Limited Retention**: 7 days instead of 30 days
3. **Storage Limits**: 2GB for Prometheus
4. **Minimal Resource Requests**: Optimized for t3.micro
5. **Efficient Alerting**: Reduced evaluation frequency

## Verification

### **Check Deployment Status:**

```bash
# Check all pods
kubectl get pods -n monitoring

# Check services
kubectl get services -n monitoring

# Check ingress
kubectl get ingress -n monitoring

# Check custom resources
kubectl get servicemonitor -n monitoring
kubectl get podmonitor -n monitoring
kubectl get prometheusrule -n monitoring
```

### **Verify Metrics Collection:**

```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Access Prometheus UI
# http://localhost:9090

# Check targets
# Go to Status -> Targets

# Check metrics
# Go to Graph and query: up{job="eks-cloudforge-app"}
```

### **Verify Grafana Access:**

```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Access Grafana UI
# http://localhost:3000
# Username: admin
# Password: admin123
```

## Troubleshooting

### **Common Issues:**

#### **1. Pods Not Starting:**

```bash
# Check pod events
kubectl describe pod -n monitoring <pod-name>

# Check logs
kubectl logs -n monitoring <pod-name>

# Check resource constraints
kubectl top pods -n monitoring
```

#### **2. Metrics Not Collected:**

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n monitoring -o yaml

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Go to http://localhost:9090/targets

# Check application metrics endpoint
kubectl port-forward -n default svc/eks-cloudforge-app-service 5000:5000
curl http://localhost:5000/metrics
```

#### **3. Grafana Not Accessible:**

```bash
# Check ingress
kubectl get ingress -n monitoring

# Check ingress controller
kubectl get pods -n ingress-nginx

# Add hostname to /etc/hosts
echo "127.0.0.1 grafana.eks-cloudforge.local" >> /etc/hosts
```

#### **4. High Resource Usage:**

```bash
# Check resource usage
kubectl top pods -n monitoring

# Check resource limits
kubectl describe pod -n monitoring <pod-name>

# Scale down if needed
kubectl scale deployment -n monitoring prometheus --replicas=1
```

### **Debugging Commands:**

```bash
# Check all monitoring resources
kubectl get all -n monitoring

# Check persistent volumes
kubectl get pvc -n monitoring

# Check events
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Check logs for all pods
kubectl logs -n monitoring -l app=prometheus
kubectl logs -n monitoring -l app=grafana
kubectl logs -n monitoring -l app=alertmanager
```

## Maintenance

### **Regular Tasks:**

#### **Weekly:**
- Review alert history
- Check resource usage
- Verify dashboard functionality
- Update Grafana dashboards if needed

#### **Monthly:**
- Review cost trends
- Optimize resource allocation
- Update Prometheus rules
- Backup Grafana dashboards

#### **Quarterly:**
- Update monitoring stack versions
- Review and optimize alerting rules
- Analyze long-term trends
- Plan capacity upgrades

### **Backup and Recovery:**

#### **Backup Grafana Dashboards:**

```bash
# Export dashboards
curl -H "Authorization: Bearer <api-token>" \
  http://grafana.eks-cloudforge.local/api/dashboards/db/eks-cloudforge-app \
  > backup-dashboard.json
```

#### **Backup Prometheus Data:**

```bash
# Create backup PVC
kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-backup
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: gp2
EOF

# Copy data
kubectl exec -n monitoring <prometheus-pod> -- tar czf /backup/prometheus-data.tar.gz /prometheus
```

## Security Considerations

### **Access Control:**

1. **Network Policies**: Restrict pod-to-pod communication
2. **RBAC**: Minimal required permissions
3. **Secrets Management**: Secure Grafana credentials
4. **TLS**: Enable HTTPS for external access

### **Security Best Practices:**

1. **Non-root Containers**: All pods run as non-root
2. **Read-only Filesystems**: Where possible
3. **Minimal Capabilities**: Drop unnecessary capabilities
4. **Regular Updates**: Keep images updated

## Next Steps

After successful monitoring deployment:

1. **Customize Dashboards**: Add application-specific panels
2. **Configure Alerts**: Set up notification channels
3. **Integrate with CI/CD**: Add monitoring to deployment pipeline
4. **Set up Logging**: Deploy ELK or Loki stack
5. **Performance Testing**: Add load testing metrics
6. **Cost Optimization**: Implement auto-scaling based on metrics

---

**Your monitoring stack is now ready for production use!** 📊 