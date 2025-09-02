#!/bin/bash

# =============================================================================
# EKS CloudForge Monitoring Deployment Script
# =============================================================================
# Deploys Prometheus, Grafana, and AlertManager with cost optimization
# Optimized for t3.micro instances

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="monitoring"
PROMETHEUS_CHART_VERSION="25.0.0"
GRAFANA_CHART_VERSION="7.0.0"
ALERTMANAGER_CHART_VERSION="0.26.0"

# =============================================================================
# FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}=============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl is installed"
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed"
        exit 1
    fi
    print_success "helm is installed"
    
    # Check if we can connect to the cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
    
    # Check if we have the required namespaces
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace $NAMESPACE does not exist, will create it"
    else
        print_success "Namespace $NAMESPACE exists"
    fi
}

create_namespace() {
    print_header "Creating Monitoring Namespace"
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace $NAMESPACE created/updated"
}

add_helm_repositories() {
    print_header "Adding Helm Repositories"
    
    # Add Prometheus community repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    
    # Update repositories
    helm repo update
    
    print_success "Helm repositories added and updated"
}

deploy_prometheus() {
    print_header "Deploying Prometheus"
    
    # Create values file for Prometheus
    cat > /tmp/prometheus-values.yaml << EOF
# Prometheus configuration optimized for t3.micro
global:
  imageTag: "v2.47.0"
  imageRepository: "prom/prometheus"
  imagePullPolicy: "IfNotPresent"
  serviceAccount:
    create: true
    annotations: {}
    name: ""
  podAnnotations: {}
  podSecurityContext:
    fsGroup: 65534
    runAsNonRoot: true
    runAsUser: 65534
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    runAsUser: 65534

prometheus:
  prometheusSpec:
    retention: 7d
    retentionSize: "2GB"
    logLevel: info
    scrapeInterval: 30s
    evaluationInterval: 30s
    externalUrl: ""
    routePrefix: /
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
    podMetadata:
      labels:
        app: prometheus
        component: prometheus
        cost-center: "monitoring"
      annotations:
        prometheus.io/scrape: "false"
    serviceMonitorSelector:
      matchLabels:
        app: eks-cloudforge-app
    podMonitorSelector:
      matchLabels:
        app: eks-cloudforge-app
    ruleSelector:
      matchLabels:
        app: eks-cloudforge-app
    alertmanagerConfigSelector:
      matchLabels:
        app: eks-cloudforge-app
    additionalScrapeConfigs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name
          - source_labels: [__meta_kubernetes_pod_container_name]
            action: replace
            target_label: container
    enableFeatures: []
    disableFeatures: []
    externalLabels:
      cluster: eks-cloudforge
      environment: dev
    externalUrl: ""
    listenLocal: false
    listenAddress: ""
    logFormat: logfmt
    logLevel: info
    minTime: ""
    maxTime: ""
    queryTimeout: 2m
    queryConcurrency: 50
    queryMaxSamples: 50000000
    queryLookbackDelta: 5m
    rules:
      alert:
        forOutageTolerance: 5m
        forGracePeriod: 10s
        resendDelay: 1m
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
                description: "Container {{ \$labels.container }} has high CPU usage"
            
            - alert: HighMemoryUsage
              expr: container_memory_usage_bytes{container="eks-cloudforge-app"} > 800000000
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "High memory usage detected"
                description: "Container {{ \$labels.container }} has high memory usage"
            
            - alert: PodDown
              expr: up{job="eks-cloudforge-app"} == 0
              for: 1m
              labels:
                severity: critical
              annotations:
                summary: "Pod is down"
                description: "Pod {{ \$labels.pod }} is down"
            
            - alert: HighResponseTime
              expr: http_request_duration_seconds{job="eks-cloudforge-app"} > 2
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "High response time detected"
                description: "Response time is high for {{ \$labels.instance }}"

alertmanager:
  alertmanagerSpec:
    image:
      repository: prom/alertmanager
      tag: v0.26.0
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 100m
        memory: 128Mi
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 1Gi
    config:
      global:
        resolve_timeout: 5m
        slack_api_url: ""
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
      inhibit_rules:
        - source_match:
            severity: 'critical'
          target_match:
            severity: 'warning'
          equal: ['alertname', 'dev', 'instance']
EOF
    
    # Deploy Prometheus
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace $NAMESPACE \
        --version $PROMETHEUS_CHART_VERSION \
        --values /tmp/prometheus-values.yaml \
        --wait \
        --timeout 10m \
        --atomic
    
    print_success "Prometheus deployed successfully"
}

deploy_grafana() {
    print_header "Deploying Grafana"
    
    # Create values file for Grafana
    cat > /tmp/grafana-values.yaml << EOF
# Grafana configuration optimized for t3.micro
image:
  repository: grafana/grafana
  tag: 10.1.0

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

persistence:
  enabled: true
  storageClassName: gp2
  accessMode: ReadWriteOnce
  size: 2Gi

adminUser: admin
adminPassword: admin123

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: grafana.eks-cloudforge.local
      paths:
        - path: /
          pathType: Prefix

dashboards:
  default:
    eks-cloudforge-app:
      gnetId: 1860
      revision: 22
      datasource: Prometheus
      folder: ""

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-operated.monitoring.svc.cluster.local:9090
        access: proxy
        isDefault: true
EOF
    
    # Deploy Grafana
    helm upgrade --install grafana grafana/grafana \
        --namespace $NAMESPACE \
        --version $GRAFANA_CHART_VERSION \
        --values /tmp/grafana-values.yaml \
        --wait \
        --timeout 10m \
        --atomic
    
    print_success "Grafana deployed successfully"
}

create_service_monitor() {
    print_header "Creating ServiceMonitor for EKS CloudForge App"
    
    # Create ServiceMonitor
    cat > /tmp/service-monitor.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: eks-cloudforge-app
  namespace: $NAMESPACE
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
  jobLabel: eks-cloudforge-app
  podTargetLabels:
    - app
  relabelings:
    - sourceLabels: [__meta_kubernetes_pod_label_app]
      targetLabel: app
    - sourceLabels: [__meta_kubernetes_namespace]
      targetLabel: namespace
    - sourceLabels: [__meta_kubernetes_pod_name]
      targetLabel: pod
EOF
    
    kubectl apply -f /tmp/service-monitor.yaml
    print_success "ServiceMonitor created successfully"
}

create_pod_monitor() {
    print_header "Creating PodMonitor for EKS CloudForge App"
    
    # Create PodMonitor
    cat > /tmp/pod-monitor.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: eks-cloudforge-app
  namespace: $NAMESPACE
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
  namespaceSelector:
    matchNames:
      - default
  jobLabel: eks-cloudforge-app
  podTargetLabels:
    - app
  relabelings:
    - sourceLabels: [__meta_kubernetes_pod_label_app]
      targetLabel: app
    - sourceLabels: [__meta_kubernetes_namespace]
      targetLabel: namespace
    - sourceLabels: [__meta_kubernetes_pod_name]
      targetLabel: pod
EOF
    
    kubectl apply -f /tmp/pod-monitor.yaml
    print_success "PodMonitor created successfully"
}

create_prometheus_rule() {
    print_header "Creating PrometheusRule for EKS CloudForge App"
    
    # Create PrometheusRule
    cat > /tmp/prometheus-rule.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: eks-cloudforge-app
  namespace: $NAMESPACE
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
            cost-center: "monitoring"
          annotations:
            summary: "High CPU usage detected"
            description: "Container {{ \$labels.container }} has high CPU usage"
            cost_impact: "May trigger auto-scaling"
        
        - alert: HighMemoryUsage
          expr: container_memory_usage_bytes{container="eks-cloudforge-app"} > 800000000
          for: 5m
          labels:
            severity: warning
            cost-center: "monitoring"
          annotations:
            summary: "High memory usage detected"
            description: "Container {{ \$labels.container }} has high memory usage"
            cost_impact: "May trigger auto-scaling"
        
        - alert: PodDown
          expr: up{job="eks-cloudforge-app"} == 0
          for: 1m
          labels:
            severity: critical
            cost-center: "monitoring"
          annotations:
            summary: "Pod is down"
            description: "Pod {{ \$labels.pod }} is down"
            cost_impact: "Service unavailable"
        
        - alert: HighResponseTime
          expr: http_request_duration_seconds{job="eks-cloudforge-app"} > 2
          for: 5m
          labels:
            severity: warning
            cost-center: "monitoring"
          annotations:
            summary: "High response time detected"
            description: "Response time is high for {{ \$labels.instance }}"
            cost_impact: "Poor user experience"
        
        - alert: HighCost
          expr: increase(container_cpu_usage_seconds_total{container="eks-cloudforge-app"}[1h]) > 3600
          for: 10m
          labels:
            severity: warning
            cost-center: "monitoring"
          annotations:
            summary: "High cost detected"
            description: "High CPU usage over 1 hour"
            cost_impact: "May exceed budget"
EOF
    
    kubectl apply -f /tmp/prometheus-rule.yaml
    print_success "PrometheusRule created successfully"
}

verify_deployment() {
    print_header "Verifying Deployment"
    
    # Check if all pods are running
    print_info "Checking pod status..."
    kubectl get pods -n $NAMESPACE
    
    # Check if services are created
    print_info "Checking services..."
    kubectl get services -n $NAMESPACE
    
    # Check if ingress is created
    print_info "Checking ingress..."
    kubectl get ingress -n $NAMESPACE
    
    # Check if ServiceMonitor is created
    print_info "Checking ServiceMonitor..."
    kubectl get servicemonitor -n $NAMESPACE
    
    # Check if PodMonitor is created
    print_info "Checking PodMonitor..."
    kubectl get podmonitor -n $NAMESPACE
    
    # Check if PrometheusRule is created
    print_info "Checking PrometheusRule..."
    kubectl get prometheusrule -n $NAMESPACE
    
    print_success "Deployment verification completed"
}

show_access_info() {
    print_header "Access Information"
    
    echo -e "${GREEN}Prometheus:${NC}"
    echo "  URL: http://prometheus-operated.monitoring.svc.cluster.local:9090"
    echo "  (Internal cluster access)"
    
    echo -e "${GREEN}Grafana:${NC}"
    echo "  URL: http://grafana.eks-cloudforge.local"
    echo "  Username: admin"
    echo "  Password: admin123"
    
    echo -e "${GREEN}AlertManager:${NC}"
    echo "  URL: http://alertmanager-operated.monitoring.svc.cluster.local:9093"
    echo "  (Internal cluster access)"
    
    echo -e "${YELLOW}Note:${NC} You may need to add the Grafana hostname to your /etc/hosts file"
    echo "  or configure DNS to point to your cluster's ingress controller"
}

show_cost_info() {
    print_header "Cost Information"
    
    echo -e "${YELLOW}Estimated Monthly Costs:${NC}"
    echo "  - Prometheus: ~$0.50 (5Gi storage)"
    echo "  - AlertManager: ~$0.10 (1Gi storage)"
    echo "  - Grafana: ~$0.20 (2Gi storage)"
    echo "  - Total Storage: ~$0.80/month"
    echo ""
    echo -e "${YELLOW}Resource Usage (on t3.micro):${NC}"
    echo "  - Prometheus: 200m CPU, 256Mi RAM"
    echo "  - AlertManager: 100m CPU, 128Mi RAM"
    echo "  - Grafana: 200m CPU, 256Mi RAM"
    echo "  - Total: 500m CPU, 640Mi RAM"
    echo "  - Remaining for app: 500m CPU, 384Mi RAM"
    echo ""
    echo -e "${GREEN}Total estimated monitoring cost: ~$1.50/month${NC}"
}

cleanup_temp_files() {
    print_header "Cleaning Up Temporary Files"
    
    rm -f /tmp/prometheus-values.yaml
    rm -f /tmp/grafana-values.yaml
    rm -f /tmp/service-monitor.yaml
    rm -f /tmp/pod-monitor.yaml
    rm -f /tmp/prometheus-rule.yaml
    
    print_success "Temporary files cleaned up"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "EKS CloudForge Monitoring Deployment"
    print_info "This script will deploy Prometheus, Grafana, and AlertManager"
    print_info "Optimized for t3.micro instances with cost monitoring"
    
    # Check prerequisites
    check_prerequisites
    
    # Create namespace
    create_namespace
    
    # Add Helm repositories
    add_helm_repositories
    
    # Deploy Prometheus
    deploy_prometheus
    
    # Deploy Grafana
    deploy_grafana
    
    # Create monitoring resources
    create_service_monitor
    create_pod_monitor
    create_prometheus_rule
    
    # Verify deployment
    verify_deployment
    
    # Show access information
    show_access_info
    
    # Show cost information
    show_cost_info
    
    # Cleanup
    cleanup_temp_files
    
    print_header "Deployment Complete"
    print_success "Monitoring stack deployed successfully!"
    print_info "You can now access Grafana at: http://grafana.eks-cloudforge.local"
    print_info "Username: admin, Password: admin123"
}

# Run main function
main "$@" 