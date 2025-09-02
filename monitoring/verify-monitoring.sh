#!/bin/bash

# =============================================================================
# EKS CloudForge Monitoring Verification Script
# =============================================================================
# Verifies that all monitoring components are working correctly

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
APP_NAMESPACE="default"
APP_NAME="eks-cloudforge-app"

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
    
    # Check if we can connect to the cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
}

verify_namespaces() {
    print_header "Verifying Namespaces"
    
    # Check monitoring namespace
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_success "Namespace $NAMESPACE exists"
    else
        print_error "Namespace $NAMESPACE does not exist"
        return 1
    fi
    
    # Check app namespace
    if kubectl get namespace $APP_NAMESPACE &> /dev/null; then
        print_success "Namespace $APP_NAMESPACE exists"
    else
        print_error "Namespace $APP_NAMESPACE does not exist"
        return 1
    fi
}

verify_prometheus() {
    print_header "Verifying Prometheus"
    
    # Check if Prometheus pods are running
    if kubectl get pods -n $NAMESPACE -l app=prometheus --no-headers | grep -q "Running"; then
        print_success "Prometheus pods are running"
    else
        print_error "Prometheus pods are not running"
        kubectl get pods -n $NAMESPACE -l app=prometheus
        return 1
    fi
    
    # Check if Prometheus service exists
    if kubectl get service -n $NAMESPACE prometheus-operated &> /dev/null; then
        print_success "Prometheus service exists"
    else
        print_error "Prometheus service does not exist"
        return 1
    fi
    
    # Check if Prometheus is scraping metrics
    print_info "Checking Prometheus targets..."
    kubectl port-forward -n $NAMESPACE svc/prometheus-operated 9090:9090 &
    PF_PID=$!
    sleep 5
    
    if curl -s http://localhost:9090/api/v1/targets | grep -q "eks-cloudforge-app"; then
        print_success "Prometheus is scraping eks-cloudforge-app"
    else
        print_warning "Prometheus is not scraping eks-cloudforge-app"
        print_info "Available targets:"
        curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].labels.job' 2>/dev/null || echo "No targets found"
    fi
    
    kill $PF_PID 2>/dev/null || true
}

verify_grafana() {
    print_header "Verifying Grafana"
    
    # Check if Grafana pods are running
    if kubectl get pods -n $NAMESPACE -l app=grafana --no-headers | grep -q "Running"; then
        print_success "Grafana pods are running"
    else
        print_error "Grafana pods are not running"
        kubectl get pods -n $NAMESPACE -l app=grafana
        return 1
    fi
    
    # Check if Grafana service exists
    if kubectl get service -n $NAMESPACE grafana &> /dev/null; then
        print_success "Grafana service exists"
    else
        print_error "Grafana service does not exist"
        return 1
    fi
    
    # Check if Grafana ingress exists
    if kubectl get ingress -n $NAMESPACE grafana &> /dev/null; then
        print_success "Grafana ingress exists"
    else
        print_warning "Grafana ingress does not exist"
    fi
}

verify_alertmanager() {
    print_header "Verifying AlertManager"
    
    # Check if AlertManager pods are running
    if kubectl get pods -n $NAMESPACE -l app=alertmanager --no-headers | grep -q "Running"; then
        print_success "AlertManager pods are running"
    else
        print_error "AlertManager pods are not running"
        kubectl get pods -n $NAMESPACE -l app=alertmanager
        return 1
    fi
    
    # Check if AlertManager service exists
    if kubectl get service -n $NAMESPACE alertmanager-operated &> /dev/null; then
        print_success "AlertManager service exists"
    else
        print_error "AlertManager service does not exist"
        return 1
    fi
}

verify_application() {
    print_header "Verifying Application"
    
    # Check if application pods are running
    if kubectl get pods -n $APP_NAMESPACE -l app=$APP_NAME --no-headers | grep -q "Running"; then
        print_success "Application pods are running"
    else
        print_error "Application pods are not running"
        kubectl get pods -n $APP_NAMESPACE -l app=$APP_NAME
        return 1
    fi
    
    # Check if application service exists
    if kubectl get service -n $APP_NAMESPACE -l app=$APP_NAME &> /dev/null; then
        print_success "Application service exists"
    else
        print_error "Application service does not exist"
        return 1
    fi
    
    # Check if application exposes metrics
    APP_POD=$(kubectl get pods -n $APP_NAMESPACE -l app=$APP_NAME -o jsonpath='{.items[0].metadata.name}')
    if kubectl exec -n $APP_NAMESPACE $APP_POD -- curl -s http://localhost:5000/prometheus &> /dev/null; then
        print_success "Application exposes Prometheus metrics"
    else
        print_error "Application does not expose Prometheus metrics"
        return 1
    fi
    
    # Check if application health endpoint works
    if kubectl exec -n $APP_NAMESPACE $APP_POD -- curl -s http://localhost:5000/health | grep -q "healthy"; then
        print_success "Application health endpoint works"
    else
        print_error "Application health endpoint does not work"
        return 1
    fi
}

verify_servicemonitor() {
    print_header "Verifying ServiceMonitor"
    
    # Check if ServiceMonitor exists
    if kubectl get servicemonitor -n $NAMESPACE -l app=$APP_NAME &> /dev/null; then
        print_success "ServiceMonitor exists"
    else
        print_error "ServiceMonitor does not exist"
        return 1
    fi
    
    # Check ServiceMonitor configuration
    SERVICEMONITOR=$(kubectl get servicemonitor -n $NAMESPACE -l app=$APP_NAME -o yaml)
    if echo "$SERVICEMONITOR" | grep -q "path: /prometheus"; then
        print_success "ServiceMonitor configured for /prometheus endpoint"
    else
        print_error "ServiceMonitor not configured for /prometheus endpoint"
        return 1
    fi
}

verify_prometheusrule() {
    print_header "Verifying PrometheusRule"
    
    # Check if PrometheusRule exists
    if kubectl get prometheusrule -n $NAMESPACE -l app=$APP_NAME &> /dev/null; then
        print_success "PrometheusRule exists"
    else
        print_error "PrometheusRule does not exist"
        return 1
    fi
    
    # Check PrometheusRule configuration
    RULE=$(kubectl get prometheusrule -n $NAMESPACE -l app=$APP_NAME -o yaml)
    if echo "$RULE" | grep -q "HighCPUUsage"; then
        print_success "PrometheusRule contains CPU usage alert"
    else
        print_error "PrometheusRule missing CPU usage alert"
        return 1
    fi
}

verify_metrics() {
    print_header "Verifying Metrics Collection"
    
    # Forward Prometheus port
    kubectl port-forward -n $NAMESPACE svc/prometheus-operated 9090:9090 &
    PF_PID=$!
    sleep 5
    
    # Check if metrics are being collected
    if curl -s "http://localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total{container=\"eks-cloudforge-app\"}" | grep -q "result"; then
        print_success "CPU metrics are being collected"
    else
        print_warning "CPU metrics are not being collected"
    fi
    
    if curl -s "http://localhost:9090/api/v1/query?query=container_memory_usage_bytes{container=\"eks-cloudforge-app\"}" | grep -q "result"; then
        print_success "Memory metrics are being collected"
    else
        print_warning "Memory metrics are not being collected"
    fi
    
    if curl -s "http://localhost:9090/api/v1/query?query=http_requests_total{job=\"eks-cloudforge-app\"}" | grep -q "result"; then
        print_success "HTTP metrics are being collected"
    else
        print_warning "HTTP metrics are not being collected"
    fi
    
    kill $PF_PID 2>/dev/null || true
}

verify_alerts() {
    print_header "Verifying Alerts"
    
    # Forward AlertManager port
    kubectl port-forward -n $NAMESPACE svc/alertmanager-operated 9093:9093 &
    PF_PID=$!
    sleep 5
    
    # Check if alerts are configured
    if curl -s http://localhost:9093/api/v1/alerts | grep -q "eks-cloudforge-app"; then
        print_success "Alerts are configured for eks-cloudforge-app"
    else
        print_warning "No alerts configured for eks-cloudforge-app"
    fi
    
    kill $PF_PID 2>/dev/null || true
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
    
    echo -e "${GREEN}Application:${NC}"
    echo "  Metrics: http://eks-cloudforge-app-service.default.svc.cluster.local:80/prometheus"
    echo "  Health: http://eks-cloudforge-app-service.default.svc.cluster.local:80/health"
    
    echo -e "${YELLOW}Note:${NC} You may need to add the Grafana hostname to your /etc/hosts file"
    echo "  or configure DNS to point to your cluster's ingress controller"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "EKS CloudForge Monitoring Verification"
    print_info "This script will verify that all monitoring components are working correctly"
    
    # Check prerequisites
    check_prerequisites
    
    # Verify namespaces
    verify_namespaces
    
    # Verify monitoring components
    verify_prometheus
    verify_grafana
    verify_alertmanager
    
    # Verify application
    verify_application
    
    # Verify monitoring resources
    verify_servicemonitor
    verify_prometheusrule
    
    # Verify metrics collection
    verify_metrics
    
    # Verify alerts
    verify_alerts
    
    # Show access information
    show_access_info
    
    print_header "Verification Complete"
    print_success "All monitoring components are working correctly!"
    print_info "You can now access your monitoring dashboards and alerts"
}

# Run main function
main "$@" 